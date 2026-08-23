#!/usr/bin/env bash
# Diagnostic (et reparation optionnelle) du SSD USB du Pi, apres une erreur
#   OSError [Errno 5] Input/output error: '/mnt/ssd/...'
#
#   sudo ./pi-ssd-check.sh            # diagnostic seul, n'ecrit rien
#   sudo ./pi-ssd-check.sh --repair   # tente demontage + fsck + remontage
#
# A lancer SUR LE PI, pas sur le Mac.

set -uo pipefail

MOUNT="${MOUNT:-/mnt/ssd}"
SERVICE="${SERVICE:-hermes}"
REPAIR=0
[ "${1:-}" = "--repair" ] && REPAIR=1

hr() { printf '\n=== %s ===\n' "$1"; }

hr "Montage de $MOUNT"
if findmnt -no SOURCE,FSTYPE,OPTIONS "$MOUNT" 2>/dev/null; then
  DEV=$(findmnt -no SOURCE "$MOUNT")
  OPTS=$(findmnt -no OPTIONS "$MOUNT")
else
  echo "$MOUNT n'est PAS monte. C'est deja l'explication de l'Errno 5."
  DEV=""
  OPTS=""
fi

case "$OPTS" in
  ro,*|*,ro|*,ro,*|ro)
    echo ">> Le systeme de fichiers est passe en LECTURE SEULE (ro)."
    echo ">> C'est la cause la plus frequente de l'Errno 5 : le noyau a"
    echo ">> rebascule le disque en ro apres une erreur d'E/S USB." ;;
esac

hr "Test d'ecriture reel"
if [ -n "$DEV" ]; then
  if touch "$MOUNT/.write-test" 2>/dev/null; then
    rm -f "$MOUNT/.write-test"
    echo "Ecriture OK -> le probleme n'est pas (ou plus) le montage."
  else
    echo "Ecriture IMPOSSIBLE -> disque en ro ou defaillant."
  fi
fi

hr "Espace disque et inodes"
df -h "$MOUNT" 2>/dev/null
df -i "$MOUNT" 2>/dev/null

hr "Erreurs noyau recentes (USB / SATA / I/O)"
dmesg 2>/dev/null | grep -iE 'i/o error|usb .*(reset|disconnect)|uas_|ata[0-9]|read-only|EXT4-fs error|scsi' \
  | tail -30 || echo "(rien, ou dmesg necessite sudo)"

hr "Alimentation / sous-tension"
if command -v vcgencmd >/dev/null 2>&1; then
  echo "throttled = $(vcgencmd get_throttled)"
  echo "  0x0 = OK. Un bit 0 ou 16 a 1 = sous-tension detectee :"
  echo "  c'est souvent LA cause des resets USB sur SSD auto-alimente."
fi

hr "Sante SMART du SSD"
if command -v smartctl >/dev/null 2>&1 && [ -n "$DEV" ]; then
  BASE=$(lsblk -no PKNAME "$DEV" 2>/dev/null)
  smartctl -a "/dev/${BASE:-sda}" 2>&1 | head -40
else
  echo "smartctl absent. Installer : sudo apt install smartmontools"
fi

hr "Fichier en cause"
ls -l "$MOUNT/hermes/platforms/pairing/" 2>&1 | head -20

if [ "$REPAIR" -eq 0 ]; then
  hr "Suite"
  echo "Diagnostic termine. Rien n'a ete modifie."
  echo "Pour tenter la reparation : sudo $0 --repair"
  exit 0
fi

# --------------------------- reparation ------------------------------------
hr "REPARATION"
[ -n "$DEV" ] || { echo "Aucun peripherique monte sur $MOUNT, rien a reparer ici."; exit 1; }

read -r -p "Arreter $SERVICE, demonter $MOUNT et lancer fsck sur $DEV ? [oui/non] " ans
[ "$ans" = "oui" ] || { echo "Annule."; exit 1; }

systemctl stop "$SERVICE" 2>/dev/null && echo "Service $SERVICE arrete." \
  || echo "Service $SERVICE introuvable ou deja arrete."

sync
if ! umount "$MOUNT"; then
  echo "Demontage refuse. Processus qui tiennent le point de montage :"
  fuser -vm "$MOUNT" 2>&1 || lsof "$MOUNT" 2>&1 | head
  echo "Arrete-les puis relance, ou redemarre le Pi (sudo reboot)."
  exit 1
fi

echo "fsck sur $DEV ..."
fsck -y "$DEV"; rc=$?
echo "fsck code de sortie = $rc  (0 ou 1 = corrige, >=4 = erreurs restantes)"

mount "$MOUNT" && echo "Remonte." || { echo "Remontage echoue."; exit 1; }
findmnt -no SOURCE,FSTYPE,OPTIONS "$MOUNT"

if touch "$MOUNT/.write-test" 2>/dev/null; then
  rm -f "$MOUNT/.write-test"
  echo "Ecriture OK."
  systemctl start "$SERVICE" 2>/dev/null && echo "Service $SERVICE redemarre."
else
  echo "Toujours en lecture seule : suspecte le cable USB, l'alimentation ou le SSD lui-meme."
fi
