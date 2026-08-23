#!/usr/bin/env bash
# Trouve le Raspberry Pi sur le reseau local. A lancer depuis n'importe quel Mac de la maison.
#
#   ./pi-find.sh            # cherche et affiche les candidats
#   ./pi-find.sh --ssh pi   # cherche puis ouvre une session SSH avec l'utilisateur "pi"
#
# Strategie :
#   1. noms mDNS habituels (hermes.local, raspberrypi.local, ...)
#   2. balayage ping du sous-reseau puis lecture de la table ARP,
#      filtree sur les prefixes MAC (OUI) de la Raspberry Pi Foundation.

set -uo pipefail

SSH_USER=""
[ "${1:-}" = "--ssh" ] && SSH_USER="${2:-pi}"

# Prefixes MAC attribues a Raspberry Pi (Trading) Ltd.
OUIS="b8:27:eb dc:a6:32 e4:5f:01 28:cd:c1 2c:cf:67 d8:3a:dd"

MDNS_NAMES="hermes.local raspberrypi.local pi.local hermes-pi.local"

say() { printf '%s\n' "$*" >&2; }

# --- 1. mDNS ---------------------------------------------------------------
found_host=""
found_ip=""
for name in $MDNS_NAMES; do
  ip=$(ping -c1 -W1000 "$name" 2>/dev/null | sed -n '1s/.*(\([0-9.]*\)).*/\1/p')
  if [ -n "$ip" ]; then
    say "mDNS  : $name -> $ip"
    [ -z "$found_host" ] && { found_host="$name"; found_ip="$ip"; }
  fi
done

# --- 2. balayage ARP -------------------------------------------------------
# Normalise un MAC macOS (b8:27:eb:1:2:3) en b8:27:eb:01:02:03
norm_mac() {
  printf '%s' "$1" | awk -F: '{for(i=1;i<=NF;i++) printf "%s%02s", (i>1?":":""), $i; print ""}' \
    | tr 'A-Z' 'a-z'
}

iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
myip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)

if [ -n "${myip:-}" ]; then
  subnet="${myip%.*}"
  say "Scan  : $subnet.0/24 via ${iface:-en0} (quelques secondes)..."
  for n in $(seq 1 254); do
    ping -c1 -W200 "$subnet.$n" >/dev/null 2>&1 &
  done
  wait

  arp -a -n 2>/dev/null | while read -r line; do
    ip=$(printf '%s' "$line" | sed -n 's/.*(\([0-9.]*\)).*/\1/p')
    raw=$(printf '%s' "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9a-fA-F]{1,2}(:[0-9a-fA-F]{1,2}){5}$/) print $i}')
    [ -n "$ip" ] && [ -n "$raw" ] || continue
    mac=$(norm_mac "$raw")
    for oui in $OUIS; do
      case "$mac" in
        "$oui":*) say "ARP   : $ip  ($mac)  <- Raspberry Pi" ;;
      esac
    done
  done
else
  say "Scan  : impossible de determiner le sous-reseau, etape ignoree."
fi

# --- 3. connexion ----------------------------------------------------------
target="${found_host:-}"
if [ -z "$target" ]; then
  say ""
  say "Aucun nom mDNS n'a repondu. Utilise une adresse IP listee ci-dessus :"
  say "  ssh ${SSH_USER:-pi}@192.168.x.y"
  exit 1
fi

if [ -n "$SSH_USER" ]; then
  say ""
  say "Connexion : ssh $SSH_USER@$target"
  exec ssh -o StrictHostKeyChecking=accept-new "$SSH_USER@$target"
fi

printf '%s\n' "$target"
