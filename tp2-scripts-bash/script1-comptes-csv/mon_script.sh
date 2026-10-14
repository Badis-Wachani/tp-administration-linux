#!/bin/bash
# Menu interactif - Création de comptes en masse

FICHIER="/srv/scripts/nouveaux.csv"

PS3="Quelle tâche souhaitez-vous exécuter ? "

options=(
  "Créer le fichier nouveaux.csv"
  "Afficher le fichier CSV"
  "Vérifier le fichier (sans créer)"
  "Créer les comptes"
  "Afficher le récapitulatif"
  "Exit"
)

select choix in "${options[@]}"; do
  case $REPLY in
    1) # créer le fichier CSV
       mkdir -p /srv/scripts
       cat > "$FICHIER" << 'EOF'
# nom,groupe,role
dev6,dev,developpeur
guest4,guest,invite
ops3,admin,administrateur
EOF
       echo "Fichier $FICHIER créé."
       ;;
    2) # afficher le fichier
       if [[ -f "$FICHIER" ]]; then
         cat -n "$FICHIER"
       else
         echo "Le fichier $FICHIER n'existe pas, utilisée d'abord l'option 1."
       fi
       ;;
    3) # vérifier sans créer
       while IFS=, read -r nom groupe role; do
         [[ -z $nom || $nom == \#* ]] && continue
         if   [[ -z $role ]];                      then echo "REJET  $nom : il manque un champ"
         elif [[ $nom == *" "* ]];                 then echo "REJET  $nom : nom invalide"
         elif ! getent group $groupe > /dev/null;  then echo "REJET  $nom : groupe inexistant"
         elif id $nom &> /dev/null;                then echo "IGNORE $nom : existe déjà"
         else echo "OK     $nom : sera créé"
         fi
       done < "$FICHIER"
       ;;
    4) # créer les comptes
       crees=0; ignores=0; rejets=0
       while IFS=, read -r nom groupe role; do
         [[ -z $nom || $nom == \#* ]] && continue
         if   [[ -z $role ]];                      then echo "REJET  $nom : il manque un champ"; rejets=$((rejets+1))
         elif [[ $nom == *" "* ]];                 then echo "REJET  $nom : nom invalide";       rejets=$((rejets+1))
         elif ! getent group $groupe > /dev/null;  then echo "REJET  $nom : groupe inexistant";  rejets=$((rejets+1))
         elif id $nom &> /dev/null;                then echo "IGNORE $nom : existe déjà";        ignores=$((ignores+1))
         else
           useradd -m -s /bin/bash -G $groupe -c "$role" $nom
           echo "CREE   $nom ($groupe)"; crees=$((crees+1))
         fi
       done < "$FICHIER"
       ;;
    5) # afficher le récapitulatif
       echo "Créés   : $crees"
       echo "Ignorés : $ignores"
       echo "Rejetés : $rejets"
       ;;
    6) echo "Au revoir"
       break
       ;;
    *) echo "Choix invalide"
       ;;
  esac
done
