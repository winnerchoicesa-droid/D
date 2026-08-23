#!/usr/bin/env bash
# Attend que le Raspberry Pi reapparaisse sur le reseau local, par exemple
# apres un redemarrage ou une coupure de courant.
#
#   ./pi-wait.sh              # surveille jusqu'a 40 cycles (~10 min)
#   CYCLES=100 ./pi-wait.sh   # surveille plus longtemps
#
# A lancer depuis un Mac. Ne modifie rien.
#
# Note zsh : lance bien ce fichier avec "bash pi-wait.sh". En zsh interactif,
# une boucle de pings en arriere-plan fait afficher une ligne "exit 2" par
# ping ; bash non interactif reste silencieux.

set -uo pipefail

CYCLES="${CYCLES:-40}"
OUIS='b8:27:eb|dc:a6:32|e4:5f:01|28:cd:c1|2c:cf:67|d8:3a:dd'
MDNS_NAMES="hermes raspberrypi pi hermes-pi"

iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
myip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)
[ -n "${myip:-}" ] || { echo "Impossible de determiner l'IP locale." >&2; exit 1; }
subnet="${myip%.*}"

echo "Surveillance de $subnet.0/24 via ${iface:-en0}, $CYCLES cycles max."
echo "Un cycle dure une quinzaine de secondes. Ctrl+C pour arreter."
echo

for t in $(seq 1 "$CYCLES"); do
  # a) resolution mDNS des noms probables
  for n in $MDNS_NAMES; do
    r=$(ping -c1 -W800 "$n.local" 2>/dev/null | sed -n '1s/.*(\([0-9.]*\)).*/\1/p')
    if [ -n "$r" ]; then
      echo; echo ">>> TROUVE : $n.local -> $r"
      echo "    ssh pi@$n.local"
      exit 0
    fi
  done

  # b) balayage ping pour peupler la table ARP, puis filtrage sur les OUI
  for i in $(seq 1 254); do
    ping -c1 -W200 "$subnet.$i" >/dev/null 2>&1 &
  done
  wait

  hit=$(arp -a -n 2>/dev/null | grep -iE "$OUIS")
  if [ -n "$hit" ]; then
    echo; echo ">>> TROUVE (MAC Raspberry Pi) :"; echo "$hit"
    ip=$(printf '%s' "$hit" | sed -n '1s/.*(\([0-9.]*\)).*/\1/p')
    echo "    ssh pi@$ip"
    exit 0
  fi

  printf '%s ' "$t"
done

echo
echo "Rien apres $CYCLES cycles."
echo "Pistes : le Pi ne demarre pas, il est sur un autre reseau, ou sa carte"
echo "reseau n'a pas un MAC Raspberry Pi. Consulte les baux DHCP de la box,"
echo "ou debranche le SSD USB et redemarre le Pi sans lui."
exit 1
