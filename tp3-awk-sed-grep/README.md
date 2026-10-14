# TP 3 : awk, sed, grep et pipelines

Fait sur la VM Ubuntu. Les fichiers qu'on a créés pour tester sont dans [`fichiers-test/`](fichiers-test/).

## 3.1 awk : analyser les comptes du système

```bash
# comptes avec un UID >= 1000
awk -F: '$3 >= 1000 {printf "%-14s uid=%-6d gid=%-6d %s\n", $1, $3, $4, $6}' /etc/passwd
```
`%d` = afficher un nombre entier, `6` = réserver 6 caractères, `-` = aligner à gauche.

```bash
# comptes sans mot de passe
sudo awk -F: '$2 == "*" {print "sans mot de passe :", $1}' /etc/shadow

# combien de comptes par shell (7e champ de /etc/passwd)
awk -F: '{compte[$7]++} END {for (s in compte) print compte[s], s}' /etc/passwd | sort -rn

# comptes dont le home n'existe pas
awk -F: '$3 >= 1000 {print $1, $6}' /etc/passwd | while read -r u h; do
    [[ -d $h ]] || echo "home absent : $u ($h)"
done
```
→ on trouve `nobody` avec `/nonexistent`. C'est un compte système, utilisé par certains services pour fonctionner avec très peu de privilèges.

```bash
# une sortie propre avec un en-tête (BEGIN s'exécute une seule fois avant de lire le fichier)
awk -F: '
BEGIN {
    printf "%-14s %-8s %-8s %s\n", "COMPTE", "UID", "GID", "HOME"
}
$3 >= 1000 {
    printf "%-14s %-8d %-8d %s\n", $1, $3, $4, $6
}
' /etc/passwd
```

**Q3.1** NF = nombre de champs et NR = numéro de ligne. Le dernier champ s'obtient avec `$NF`.
**Q3.2** awk a sa propre syntaxe : enlever les guillemets simples ferait interpréter `$1`, `$3` par le shell au lieu d'awk.
**Q3.3** Un compte peut exister sans répertoire personnel.

## 3.2 sed : modifier des configurations en série

```bash
# 1. tester à blanc : on compare le résultat prévu avec le fichier, sans le modifier
sed 's/^\(\s*port:\s*\)[0-9]\+/\18443/' config.yml | diff - config.yml

# 2. appliquer sur un fichier, avec une copie .bak
sed -i.bak -E 's/^(\s*port:\s*)8080/\18443/' config.yml

# 3. lister tous les fichiers concernés (tee affiche ET enregistre)
grep -rl 'port: 8080' ~/config-test/ | tee /tmp/liste.txt

# 4. appliquer sur toute la liste
xargs -a /tmp/liste.txt -r sed -i.bak -E 's/^(\s*port:\s*)8080/\18443/'

# 5. si ça casse : on remet les .bak
for f in $(cat /tmp/liste.txt); do mv -f "$f.bak" "$f"; done
```
La ligne commentée `# port: 8080` n'est pas touchée grâce au `^`.

**Q3.5 La bonne procédure :** vérifier le résultat à blanc → appliquer avec `-i.bak` sur un fichier → appliquer avec `-i.bak` sur tous les fichiers → restaurer avec une boucle `for` et `mv` du `.bak` si problème.

## 3.3 grep et expressions régulières sur les journaux

```bash
# les adresses IP sans doublons
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' journal.txt | sort -u

# adresses mail internes puis externes
grep -oE '[a-zA-Z0-9._%+-]+@entreprise\.local' journal.txt | sort -u
grep -oE '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}' journal.txt | grep -v '@entreprise\.local' | sort -u

# nombre d'erreurs par heure
grep "ERROR" journal.txt | grep -oE '^[0-9-]+ [0-9]{2}' | uniq -c

# 3 lignes avant et après le CRITICAL
grep -n -C3 "CRITICAL" journal.txt | head -40

# vérifier qu'un motif est présent / absent
if grep -q "panic" journal.txt; then echo "alerte" ; else echo "aucun incident" ; fi

# point de contrôle : nombre d'adresses distinctes (4 pour nous)
grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' journal.txt | sort -u | wc -l
```
`[0-9]{1,3}` = un chiffre de 0 à 9, jusqu'à trois fois de suite (ex : 192).

**Q3.7** `grep 'abc'` cherche n'importe où dans la ligne, `'^abc'` en début de ligne, `'abc$'` en fin de ligne.
**Q3.8** Le tri compare les caractères et pas les valeurs numériques.
**Q3.9** Avec `grep -q` dans un `if ... else` et un `echo` pour afficher le résultat.

## 3.4 Pipelines et one-liners d'exploitation

```bash
# les 10 adresses les plus actives
tail -n 1000 access.log | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

# volumes utilisés à plus de 10 %
df -P | awk 'NR>1 && $5+0 > 10 {printf "%-24s %5s\n", $6, $5}'

# les 10 plus gros éléments de /var
sudo du -ah /var | sort -rh | head -10

# ports en écoute (-tulpn : TCP, UDP, processus, adresses et ports)
ss -tulpn | awk 'NR>1 {print $1, $5}' | sort -u

# remplacer un mot dans tous les fichiers d'un dossier, avec sauvegarde
grep -rl 'ancien' ~/test-remplacement | xargs -r sed -i.bak 's/ancien/nouveau/g'
```

**Q3.10** Le pipeline met les adresses IPv4 dans l'ordre décroissant, des plus actives aux moins actives.
**Q3.11** `xargs` transmet à `sed` les noms de fichiers trouvés par `grep`. Sans lui, `sed` recevrait du texte au lieu de noms de fichiers.
**Q3.12** Pour comparer correctement les fréquences en tant que nombres, et avoir les plus grandes en premier.
