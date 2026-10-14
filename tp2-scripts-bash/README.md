# TP 2 : Trois scripts Bash

Pour ce TP, on l'a fait d'une autre manière : au lieu d'un script qui fait tout d'un coup, chaque script a un **menu interactif** avec `select`, et on choisit l'étape qu'on veut exécuter. Ça nous a permis de tester chaque partie une par une.

Ce qu'il faut savoir pour comprendre les menus :
- `break` : sort de la boucle select
- `;;` : termine chaque case
- `*)` : attrape tout numéro qui n'est pas dans la liste
- `$REPLY` : ce que l'utilisateur a tapé (le chiffre), et `case $valeur in` regarde ce que contient `$valeur`

---

## Script 1 : Création d'utilisateurs en lot depuis un CSV

📁 [`script1-comptes-csv/`](script1-comptes-csv/)

```bash
chmod 700 mon_script.sh     # seul badis peut lire, modifier et exécuter
sudo ./mon_script.sh
```

| Option | Ce qu'elle fait |
|---|---|
| 1 | Crée `/srv/scripts/nouveaux.csv` (avec une ligne de commentaire en tête) |
| 2 | Affiche le CSV, contrôle visuel avant traitement |
| 3 | Vérifie le fichier **sans rien créer** |
| 4 | Crée les comptes, en sautant ceux qui existent déjà |
| 5 | Affiche le récap : créés / ignorés / rejetés |
| 6 | Quitter |

`cat > "$FICHIER" << 'EOF'` copie les lignes dans le fichier et s'arrête dès qu'il voit `EOF`.

REJET = une ligne où il manque un champ, un nom invalide (avec un espace) ou un groupe qui n'existe pas. IGNORE = le compte existe déjà, donc on le recrée pas.

Le résultat quand on relance le script alors que les comptes existent déjà :

```
IGNORE dev6 : existe déjà
IGNORE guest4 : existe déjà
IGNORE ops3 : existe déjà
Créés   : 0
Ignorés : 3
Rejetés : 0
```

**Q2.1 Pourquoi la redirection se place après `done` et pas après `read` ?**
`done` signifie la fin de la boucle, c'est pour ça. `read` lit la ligne suivante, et si on met la redirection à côté du `while read`, il relit toujours la première ligne = boucle infinie.

**Q2.2 C'est quoi un script idempotent ?**
Un script est idempotent quand on peut l'exécuter une fois ou plusieurs fois avec le même résultat final. C'est indispensable sur un parc de cent serveurs car le déploiement n'est jamais parfait, avec beaucoup de variables.

**Q2.3 Pourquoi une ligne invalide ne doit pas arrêter les suivantes ?**
Sinon le script ne sera pas utilisable : il s'arrête à la ligne invalide et les comptes suivants ne sont jamais créés.

---

## Script 2 : Santé du serveur

📁 [`script2-sante/`](script2-sante/)

Même plan que le script 1, mais cette fois on a mis chaque vérification dans une **fonction** pour que le code soit pas horrible à lire, et on a ajouté un **compteur d'alertes**.

```bash
sudo ./sante.sh
```

| Option | Fonction | Ce qu'elle vérifie |
|---|---|---|
| 1 | `verifier_charge` | charge CPU (`/proc/loadavg`) comparée au nombre de CPU (`nproc`) |
| 2 | `verifier_disque` | `df --output=pcent,target`, seuil 80 % |
| 3 | `verifier_inodes` | pareil avec `ipcent`, seuil 80 % |
| 4 | `verifier_memoire` | `MemAvailable` / `MemTotal` dans `/proc/meminfo`, minimum 15 % |
| 5 | `verifier_systemd` | `systemctl --failed` |
| 6 | `rapport_complet` | tout à la suite + la synthèse |
| 7 | | affiche les seuils |
| 8 | | quitte avec le code 1 s'il y a eu des alertes, 0 sinon |

Quelques trucs qu'on a appris en l'écrivant :
- `$variable` : on lit ce qu'il y a dedans. Sans `$`, on écrit dans la variable.
- `-x tmpfs -x devtmpfs` : pour exclure les systèmes de fichiers virtuels.
- `awk` : lire ou choisir des colonnes et produire un résultat (filtre et calcule).
- Pour tester l'option 5, on a créé exprès un service qui échoue (`test-echec.service` avec `/bin/false`), et l'alerte remonte bien.

```
===== Santé de rhel9-lab - 09/10/2026 13:54 =====
OK     Charge : 0.00 pour 3 CPU (limite 3)
OK     Disque : tous les volumes sous 80 %
OK     Inodes : tous les volumes sous 80 %
OK     Mémoire : 84 % disponible (seuil 15 %)
OK     Systemd : aucune unité en échec
=== Synthèse : 0 alerte(s) ===
```

**Q2.4 Pourquoi comparer la charge au nombre de CPU ?**
La charge indique combien de processus veulent utiliser le processeur. En la comparant au nombre de CPU, le seuil s'adapte à toutes les machines.

**Q2.5 Alerte inodes alors qu'il reste de l'espace ?**
Chaque fichier utilise un inode et le nombre est limité. Si y'a une alerte sur les inodes, on pourra plus créer de nouveaux fichiers même avec de l'espace disque dispo. On vérifie avec `df -i`.

**Q2.6 Pourquoi un code de sortie non nul ?**
Un programme renvoie 0 quand il va bien et une valeur non nulle en cas de problème. L'information sert à la machine ou à des outils comme cron.

---

## Script 3 : Sauvegarde avec compression et rotation

📁 [`script3-sauvegarde/`](script3-sauvegarde/)

On a fait le menu avec les options (`-s` source, `-d` destination, `-c` compression, `-r` rétention, `-v` verbeux, `-h` aide). **La partie copie / compression / rotation n'est pas encore finie**, c'est la prochaine étape.

**Q2.7 Pourquoi vérifier l'espace avant de copier ?**
Si le disque se remplit pendant la copie, on a une archive incomplète et inutilisable.

**Q2.8 Pourquoi le nettoyage dans un `trap` et pas à la fin ?**
Si le script s'arrête avant la fin (erreur, Ctrl+C), le nettoyage à la fin n'est jamais exécuté.

**Q2.9 Sauvegarde ou snapshot de VM ?**
Un snapshot permet de revenir rapidement à un état précédent, mais il est stocké avec la VM : si la VM est perdue, on perd tout. Avec une sauvegarde, on récupère l'intégralité.
