#!/bin/bash

echo "=========================================="
echo "     AUDIT DE DURCISSEMENT - TP 1.5"

echo
echo "1. PARTITIONNEMENT / VAR ET /VAR/LOG"
echo "------------------------------------------"
lsblk -f
echo
findmnt /var
findmnt /var/log

echo
echo "2. ESPACE LIBRE DANS LE GROUPE LVM"
echo "------------------------------------------"
sudo vgs

echo
echo "3. MISES A JOUR"
echo "------------------------------------------"
apt list --upgradable 2>/dev/null

echo
echo "4. SERVICES EN ECHEC"
echo "------------------------------------------"
systemctl --failed

echo
echo "5. COMPTE ROOT"
echo "------------------------------------------"
sudo passwd -S root

echo
echo "6. CONFIGURATION SSH"
echo "------------------------------------------"
sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|pubkeyauthentication|allowusers|maxauthtries'

echo
echo "7. COMPTES SANS MOT DE PASSE"
echo "------------------------------------------"
sudo awk -F: '$2=="*" {print $1}' /etc/shadow


echo
echo "8. CONFIGURATION RESEAU"
echo "------------------------------------------"
ip -br a
ip route

echo
