# TP 4.1 : Deux interfaces réseau, agrégation et bascule

## 4.1.1 : Ajouter une deuxième carte réseau

On ajoute une 2e carte réseau à la VM dans VMware : on a maintenant `ens160` et `ens224`.

## 4.1.2 : Créer le bond

```bash
sudo nmcli con add type bond con-name bond0 ifname bond0 bond.options "mode=active-backup,miimon=100"
```

- `bond` : crée une agrégation de cartes
- `mode=active-backup` : le mode actif/secours
- `miimon=100` : vérifie l'état des liens toutes les 100 ms

## 4.1.3 : Rattacher les deux cartes et mettre l'IP sur le bond

```bash
sudo nmcli con add type ethernet con-name bond0-port1 ifname ens160 master bond0
sudo nmcli con add type ethernet con-name bond0-port2 ifname ens224 master bond0
sudo nmcli con mod bond0 ipv4.method manual ipv4.addresses 10.0.0.10/24
sudo nmcli con up bond0

nmcli con show     # bond0-port1 et bond0-port2 = ethernet
ip -br a           # bond0 UP avec 10.0.0.10/24
```

```
lo        UNKNOWN   127.0.0.1/8 ::1/128
ens160    UP
ens224    UP
bond0     UP        10.0.0.10/24 fe80::ced1:4fb8:e5c3:b5e1/64
```

## Nos réponses

**Q4.1 Actif/secours ou agrégation ?**
En actif/secours, une carte réseau travaille et quand elle tombe, l'autre prend le relais : c'est pour la fiabilité. L'agrégation utilise toutes les cartes en même temps pour plus de débit.

**Q4.2 Pourquoi l'adresse est sur le bond et pas sur une carte ?**
Si l'adresse est sur une carte et qu'elle tombe, la machine n'est plus joignable. Sur `bond0`, l'adresse IP reste la même quoi qu'il arrive.

**Q4.3 Comment prouver la continuité de service ?**
On lance un ping continu depuis une autre machine et on coupe la carte active avec `nmcli device disconnect ens160`, pour voir s'il y a des pertes.
