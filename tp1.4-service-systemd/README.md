# TP 1.4 : Un service systemd maison et ses journaux

Le but : demander à systemd de gérer notre programme sous un compte dédié `monapp`, puis de planifier son exécution avec un timer. Fait sur la VM Ubuntu.

## Les fichiers

| Fichier | Où il va sur le serveur |
|---|---|
| [`monapp.sh`](monapp.sh) | `/srv/monapp/monapp.sh` |
| [`monapp.service`](monapp.service) | `/etc/systemd/system/monapp.service` |
| [`monapp.timer`](monapp.timer) | `/etc/systemd/system/monapp.timer` |

## Les étapes

```bash
# compte système sans shell ni home
sudo useradd --system --no-create-home --shell /usr/sbin/nologin monapp
sudo mkdir -p /srv/monapp /var/log/monapp
sudo chown monapp:monapp /srv/monapp /var/log/monapp
ls -ld /srv/monapp /var/log/monapp

# on vérifie que monapp peut exécuter le script
sudo mv /srv/monapp.sh /srv/monapp/monapp.sh
sudo -u monapp bash /srv/monapp/monapp.sh

# le service
sudo systemctl daemon-reload
sudo systemctl enable --now monapp.service
systemctl status monapp.service

# le timer
sudo systemctl enable --now monapp.timer
systemctl status monapp.timer
systemctl list-timers --all

# voir les exécutions de la journée
journalctl -u monapp.service --since today
```

Ces répertoires appartiennent au compte `monapp` pour que le service puisse fonctionner avec ce compte dédié.

Le status nous confirme le succès : le script s'est exécuté, a affiché la date et l'espace disque disponible, puis s'est terminé avec le code `0`.

Le service dépend de la disponibilité du réseau (`network-online.target`) et redémarre tout seul en cas d'échec (`Restart=on-failure`). Le timer le relance toutes les minutes à peu près, on le voit bien dans `journalctl`.
