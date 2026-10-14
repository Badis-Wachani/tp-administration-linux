#!/bin/bash

#valeur
SOURCE=""
DEST=""
COMPRESSION=0     # 0 = non, 1 = oui
RETENTION=7       # nombre d'archives à garder
VERBEUX=0         # 0 = non, 1 = oui

PS3="Votre choix : "
select option in "-s source" "-d destination" "-c compression" "-r retention" "-v verbeux" "-h aide" "Quitter"; do
    case "$option" in
        "-s source")      read -rp "Dossier source : " SOURCE ;;
        "-d destination") read -rp "Dossier destination : " DEST ;;
        "-c compression") COMPRESSION=1; echo "Compression activée" ;;
        "-r retention")   read -rp "Nombre d'archives à garder : " RETENTION ;;
        "-v verbeux")     VERBEUX=1; echo "Mode verbeux activé" ;;
        "-h aide")        echo "Choisissez une option avec son numéro" ;;
        "Quitter")        break ;;
        *)                echo "Choix invalide" ;;
    esac
done

# TODO : la copie, la compression (tar), la rotation et le trap de nettoyage
