# TP 1.3 : Dix comptes, trois rôles, permissions et ACL

## 1.3.1 : Créer 3 groupes

```bash
sudo groupadd admin
sudo groupadd dev
sudo groupadd guest
```

## 1.3.2 : Créer 2 admin, 5 dev, 3 guest

```bash
getent group admin dev guest wheel
```

```
admin:x:1002:karim,david
dev:x:1003:lucas,ema,badise,gege,ahmed
guest:x:1004:yacine,luffy,ipman
wheel:x:10:badis,karim,david
```

`wheel` : c'est le groupe administrateurs sur Red Hat (l'équivalent de `sudo` sur Ubuntu).

## 1.3.3 : Créer l'arborescence

```bash
sudo mkdir -p /srv/{equipe,public,confidentiel}
sudo chown root:dev   /srv/equipe
sudo chown root:admin /srv/public
sudo chown root:admin /srv/confidentiel
```

Et ensuite on définit les permissions et les ACL sur chaque dossier.

## Sur Ubuntu

On a refait les comptes sur la VM Ubuntu, on les retrouve dans le TP 3 avec `awk` :

```
admin            1001     1001     /home/admin
administrateur1  1002     1001     /home/administrateur1
administrateur2  1003     1001     /home/administrateur2
dev1 ... dev5    1004-1008  1002   /home/devX
guest1 ... guest3 1009-1011 1003   /home/guestX
```
