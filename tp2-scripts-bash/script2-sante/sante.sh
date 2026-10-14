#!/bin/bash
#Script Santé : Menu interactif + compteur d'alertes.
SEUIL_CHARGE=1
SEUIL_DISQUE=80
SEUIL_INODES=80
SEUIL_MEMOIRE=15
ALERTES=0

menu() {
  PS3="Quelle vérification souhaitez-vous exécuter ? "

  options=(
    "Contrôler la charge système"
    "Contrôler l'espace disque"
    "Contrôler les inodes"
    "Contrôler la mémoire"
    "Lister les unités systemd en échec"
    "Rapport complet"
    "Afficher les seuils"
    "Exit"
  )

  select choix in "${options[@]}"; do
    case $REPLY in
      1) verifier_charge ;;
      2) verifier_disque ;;
      3) verifier_inodes ;;
      4) verifier_memoire ;;
      5) verifier_systemd ;;
      6) rapport_complet ;;
      7) echo "Charge  : $SEUIL_CHARGE x nombre de CPU"
         echo "Disque  : $SEUIL_DISQUE %"
         echo "Inodes  : $SEUIL_INODES %"
         echo "Mémoire : $SEUIL_MEMOIRE % disponible minimum"
         ;;
      8) echo "Au revoir ($ALERTES alerte(s))"
         if [[ $ALERTES -gt 0 ]]; then exit 1; else exit 0; fi
         ;;
      *) echo "Choix invalide" ;;
    esac
  done
}

verifier_charge(){
  charge=$(cut -d' ' -f1 /proc/loadavg)
  entier=${charge%.*}
  cpu=$(nproc)
  limite=$((cpu * SEUIL_CHARGE)) #normalement 1

  if [[ $entier -ge $limite ]]; then
    echo "ALERTE Charge : $charge pour $cpu CPU (limite $limite)"
    ALERTES=$((ALERTES+1))
  else
    echo "OK     Charge : $charge pour $cpu CPU (limite $limite)"
  fi
}

verifier_disque() {
  probleme=0
  while read -r pourcent point; do
    pourcent=${pourcent%\%}
    if [[ $pourcent -gt $SEUIL_DISQUE ]]; then
      echo "ALERTE Disque : $point est rempli à $pourcent % (seuil $SEUIL_DISQUE %)"
      ALERTES=$((ALERTES+1))
      probleme=1
    fi
  done < <(df --output=pcent,target -x tmpfs -x devtmpfs | tail -n +2)

  if [[ $probleme -eq 0 ]]; then
    echo "OK     Disque : tous les volumes sous $SEUIL_DISQUE %"
  fi
}

verifier_inodes() {
  probleme=0
  while read -r pourcent point; do
    pourcent=${pourcent%\%}
    if [[ $pourcent == "-" ]]; then
      continue
    fi
    if [[ $pourcent -gt $SEUIL_INODES ]]; then
      echo "ALERTE Inodes : $point utilise $pourcent % de ses inodes (seuil $SEUIL_INODES %)"
      ALERTES=$((ALERTES+1))
      probleme=1
    fi
  done < <(df --output=ipcent,target -x tmpfs -x devtmpfs | tail -n +2)

  if [[ $probleme -eq 0 ]]; then
    echo "OK     Inodes : tous les volumes sous $SEUIL_INODES %"
  fi
}

verifier_memoire() {
  total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
  dispo=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
  pourcent=$((dispo * 100 / total))

  if [[ $pourcent -lt $SEUIL_MEMOIRE ]]; then
    echo "ALERTE Mémoire : $pourcent % disponible (seuil $SEUIL_MEMOIRE %)"
    ALERTES=$((ALERTES+1))
  else
    echo "OK     Mémoire : $pourcent % disponible (seuil $SEUIL_MEMOIRE %)"
  fi
}

verifier_systemd() {
  nombre=$(systemctl --failed --no-legend | wc -l)

  if [[ $nombre -gt 0 ]]; then
    echo "ALERTE Systemd : $nombre unité(s) en échec :"
    systemctl --failed --no-legend
    ALERTES=$((ALERTES+1))
  else
    echo "OK     Systemd : aucune unité en échec"
  fi
}

rapport_complet() {
  ALERTES=0   # on remet le compteur à 0 avant le rapport
  echo "===== Santé de $(hostname) - $(date '+%d/%m/%Y %H:%M') ====="
  verifier_charge
  verifier_disque
  verifier_inodes
  verifier_memoire
  verifier_systemd
  echo "=== Synthèse : $ALERTES alerte(s) ==="
}

menu   #lance le menu
