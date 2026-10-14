# TP 1.1 et 1.2 : Installation RHEL 9 et SSH durci par clés

## TP 1.1 : Installer et partitionner (VM Red Hat)

VM `rhel9-lab` : 60 Gio en UEFI, partitionnée en LVM.

- **LVM** : on ajoute une couche intermédiaire. Le disque est d'abord versé dans un réservoir, puis on puise dans ce réservoir pour créer des volumes.
- **Partition standard** : le disque est découpé directement en morceaux, posés les uns à côté des autres, comme des tranches de gâteau.

On a choisi **XFS** car il gère des systèmes de fichiers et des fichiers beaucoup plus grands qu'ext4. Combiné à LVM, on agrandit un volume XFS sans démonter ni arrêter quoi que ce soit.

### Post-installation

```bash
# 6.1 identité
hostnamectl

# 6.2 fuseau horaire
timedatectl

# 6.4 on verrouille root et on vérifie qu'il ne peut pas se connecter en SSH
sudo passwd -l root
sudo passwd -S root
echo "PermitRootLogin no" | sudo tee /etc/ssh/sshd_config.d/01-no-root.conf
sudo systemctl restart sshd

# 6.5 pare-feu actif à chaque démarrage
sudo systemctl enable --now firewalld
sudo firewall-cmd --state
sudo firewall-cmd --list-all

# 6.6 services qui ont échoué au démarrage
systemctl --failed

# 6.7 droits Red Hat + dépôts (après 2 jours de combat)
sudo subscription-manager refresh
sudo dnf repolist

# 6.8 mises à jour (132 paquets pour nous)
sudo dnf upgrade -y

# 6.10 langue
sudo dnf install -y glibc-langpack-fr
localectl
```

### Vérifications (7.1)

```bash
lsblk -f        # disque, partitions, volumes LVM, format (xfs, swap) et point de montage
df -hT          # taille, espace utilisé, type de chaque système de fichiers
swapon --show   # vérifier que le swap est bien activé
```

## TP 1.2 : Réseau fixe et SSH durci

```bash
ip -br link        # cartes réseau, état UP / DOWN, adresse MAC (-br = affichage court)
ip addr show ens160
ip route           # on doit voir "proto static" au lieu de dhcp
```

Le /24 signifie 255.255.255.0, soit 254 machines possibles sur le réseau.

### Clés SSH

```bash
ssh-keygen -t ed25519 -C "badis@redhatubuntu"
ls -l ~/.ssh/
ssh-copy-id rhel9-lab
```

Côté serveur, la clé publique va dans `~/.ssh/authorized_keys`. Droits obligatoires : 700 sur `~/.ssh`, 600 sur `authorized_keys` (sinon sshd refuse la clé).

Les fichiers de config sont dans [`config/`](config/) :
- [`ssh_config-client`](config/ssh_config-client) : le `~/.ssh/config` côté PC
- [`sshd_config-redhat`](config/sshd_config-redhat) : les six directives côté serveur

| Directive | Valeur | Pourquoi |
|---|---|---|
| PermitRootLogin | no | root ne se connecte pas en SSH |
| PasswordAuthentication | no | plus de connexion par mdp |
| PubkeyAuthentication | yes | seule connexion par clé |
| MaxAuthTries | 3 | coupe au bout de 3 tentatives |
| X11Forwarding | no | désactivé affichage GUI |
| AllowUsers | badis | seul badis peut se log en SSH |

```bash
sudo sshd -t                                  # juste pour valider la syntaxe
sudo systemctl reload sshd
sudo sshd -T | grep -i permitrootlogin        # -i = ne tient pas compte des majuscules
sudo journalctl -u sshd                       # lire le journal
sudo tail -n 30 /var/log/secure               # les 30 dernières lignes
sudo journalctl -u sshd | grep -i "not allowed"   # trouver le compte refusé (root)
```

### Test de survie

On a testé `ssh root@10.0.0.10`, `ssh test@10.0.0.10` et une connexion sans clé : tout est refusé (`Permission denied (publickey...)`). Seul badis passe, et il est obligé d'avoir la passphrase.

## Nos réponses aux questions

**Q1.1 Pourquoi /boot reste une partition classique ?**
Le /boot ne sera jamais rempli, donc on part sur une partition classique, c'est plus simple et plus fiable pour qu'il y accède. En plus /boot a une petite taille et donc il est stable, on a pas besoin d'agrandir son stockage.

**Q1.2 Si une application remplit /var/log ?**
S'il est sur la racine et que la racine est saturée, alors les services plantent, mise à jour impossible et même le système impossible à redémarrer. Alors que si on le sépare de la racine, on perd les nouveaux journaux, mais le système n'est pas impacté.

**Q1.3 Pourquoi garder de l'espace libre non alloué ?**
Pour que plus tard on puisse agrandir le volume logique dont on a besoin.

**Q1.4 Pourquoi valider la syntaxe avant de recharger ?**
Pour vérifier qu'il n'y a pas d'erreur et éviter de perdre la main si on travaille à distance et qu'on a pas le poste physique.

**Q1.5 Changer le port 22 en 2222, ça sécurise ?**
Oui car par défaut le port SSH est 22, ça protège un peu plus contre les bots qui scannent automatiquement le port 22.

**Q1.6 Ce que `sshd -T` apporte en plus du fichier ?**
Il affiche toutes les options, en gros ce que sshd applique réellement, et ça évite les conflits.
