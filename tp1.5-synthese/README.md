# TP 1.5 : Synthèse et vérifications

## Agrandir un volume

Le volume groupe avait un espace libre de 6 Giga. On a agrandi le LV (logical volume) `/log`, qui fait maintenant 11 Giga, puis il faut agrandir le système de fichiers derrière.

```bash
sudo vgs                                   # combien il reste de libre dans le VG
sudo lvextend -L +6G /dev/<vg>/<lv_log>    # agrandit seulement le LV
sudo resize2fs /dev/<vg>/<lv_log>          # puis le système de fichiers (ext4)
df -hT /var/log                            # vérifier
```

## Le script d'audit

Pour faire la check-list de sécurité du serveur, on a fait un script qui regroupe directement toutes les commandes nécessaires : [`audit_durcissement.sh`](audit_durcissement.sh)

```bash
sudo bash ~/audit_durcissement.sh
```

Il vérifie en 8 parties : partitionnement de /var et /var/log, espace libre LVM, mises à jour, services en échec, compte root, config SSH, comptes sans mot de passe et réseau.

## Les snapshots

On a fait un snapshot VMware à chaque étape importante, ça nous a sauvé plus d'une fois :
`avant installation` → `Partition du stockage` → `username et mot de passe` → `Point de contrôle 1.1` → `avant network fixe` → `Le ssh + clé est terminé` → `ssh terminé - durcissement` → `1.3 terminé` → `Audit durcissement`
