#!/usr/bin/env bash
# Trouve le Raspberry Pi sur le reseau local. A lancer depuis n'importe quel Mac de la maison.
#
#   ./pi-find.sh            # cherche et affiche les candidats
#   ./pi-find.sh --ssh pi   # cherche puis ouvre une session SSH avec l'utilisateur "pi"
#
# Trois methodes, de la plus fiable a la plus brutale :
#   1. dns-sd : liste les machines qui annoncent un service SSH en Bonjour
#   2. noms mDNS habituels (hermes.local, raspberrypi.local, ...)
#   3. balayage ping du sous-reseau + table ARP filtree sur les prefixes MAC
#      (OUI) de la Raspberry Pi Foundation

set -uo pipefail

SSH_USER=""
[ "${1:-}" = "--ssh" ] && SSH_USER="${2:-pi}"

OUIS="b8:27:eb dc:a6:32 e4:5f:01 28:cd:c1 2c:cf:67 d8:3a:dd"
MDNS_NAMES="hermes.local raspberrypi.local pi.local hermes-pi.local"

say() { printf '%s\n' "$*" >&2; }

found_host=""

# --- 1. Bonjour / dns-sd ---------------------------------------------------
if command -v dns-sd >/dev/null 2>&1; then
  say "[1/3] Bonjour : recherche des machines qui annoncent SSH (5 s)..."
  tmp=$(mktemp)
  dns-sd -B _ssh._tcp local. >"$tmp" 2>&1 &
  dnspid=$!
  sleep 5
  kill "$dnspid" 2>/dev/null
  wait "$dnspid" 2>/dev/null

  # Lignes du type : "12:00:00.000  Add  3  4 local. _ssh._tcp. hermes"
  names=$(awk '/_ssh\._tcp/ && $2=="Add" {name=""; for(i=7;i<=NF;i++) name=name (i>7?" ":"") $i; if (name!="") print name}' "$tmp" | sort -u)
  rm -f "$tmp"

  # Le Mac local s'annonce aussi : on l'ecarte.
  me=$(scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null)

  if [ -n "$names" ]; then
    printf '%s\n' "$names" | while IFS= read -r n; do say "      annonce : $n"; done

    # On ne retient qu'un nom sans espace (utilisable tel quel en .local),
    # different du Mac courant, en privilegiant ceux qui ressemblent au Pi.
    pick=$(printf '%s\n' "$names" \
      | grep -v ' ' \
      | grep -vix "${me:-__none__}" \
      | grep -iE 'hermes|raspberry|^pi$|-pi$|^pi-' | head -1)
    [ -n "$pick" ] && found_host="$pick.local"
  else
    say "      rien annonce en Bonjour."
  fi
fi

# --- 2. noms mDNS connus ---------------------------------------------------
say "[2/3] mDNS : test des noms habituels..."
for name in $MDNS_NAMES; do
  ip=$(ping -c1 -W1000 "$name" 2>/dev/null | sed -n '1s/.*(\([0-9.]*\)).*/\1/p')
  if [ -n "$ip" ]; then
    say "      $name -> $ip"
    [ -z "$found_host" ] && found_host="$name"
  fi
done
[ -n "$found_host" ] || say "      aucun nom connu ne repond."

# --- 3. balayage ARP -------------------------------------------------------
# Normalise un MAC tronque par arp sous macOS : b8:27:eb:1:2:3 -> b8:27:eb:01:02:03
norm_mac() {
  printf '%s' "$1" | awk -F: '{s=""; for(i=1;i<=NF;i++) s=s (i>1?":":"") sprintf("%02s",$i); print s}' \
    | tr ' A-Z' '0a-z'
}

iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
myip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)

if [ -n "${myip:-}" ]; then
  subnet="${myip%.*}"
  say "[3/3] Balayage de $subnet.0/24 via ${iface:-en0} (~15 s)"
  printf '      ' >&2
  # Par paquets de 32 pour ne pas saturer, avec un point de progression.
  n=1
  while [ "$n" -le 254 ]; do
    end=$((n + 31)); [ "$end" -gt 254 ] && end=254
    i=$n
    while [ "$i" -le "$end" ]; do
      ping -c1 -W300 "$subnet.$i" >/dev/null 2>&1 &
      i=$((i + 1))
    done
    wait
    printf '.' >&2
    n=$((end + 1))
  done
  printf '\n' >&2

  hits=0
  while IFS= read -r line; do
    ip=$(printf '%s' "$line" | sed -n 's/.*(\([0-9.]*\)).*/\1/p')
    raw=$(printf '%s' "$line" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9a-fA-F]{1,2}(:[0-9a-fA-F]{1,2}){5}$/) print $i}')
    [ -n "$ip" ] && [ -n "$raw" ] || continue
    mac=$(norm_mac "$raw")
    for oui in $OUIS; do
      case "$mac" in
        "$oui":*)
          say "      $ip  ($mac)  <- Raspberry Pi"
          hits=$((hits + 1))
          [ -z "$found_host" ] && found_host="$ip"
          ;;
      esac
    done
  done <<< "$(arp -a -n 2>/dev/null)"
  [ "$hits" -gt 0 ] || say "      aucun MAC Raspberry Pi dans la table ARP."
else
  say "[3/3] Sous-reseau indeterminable, balayage ignore."
fi

# --- resultat --------------------------------------------------------------
say ""
if [ -z "$found_host" ]; then
  say "Pi introuvable automatiquement. Pistes :"
  say "  - l'interface de la box (souvent http://192.168.1.1) liste les appareils"
  say "  - verifier que le Pi est allume et sur le meme reseau (pas un Wi-Fi invite)"
  say "  - une fois l'IP connue : ssh ${SSH_USER:-pi}@192.168.x.y"
  exit 1
fi

say "Cible retenue : $found_host"
if [ -n "$SSH_USER" ]; then
  say "Connexion : ssh $SSH_USER@$found_host"
  exec ssh -o StrictHostKeyChecking=accept-new "$SSH_USER@$found_host"
fi
say "Pour te connecter : ssh ${SSH_USER:-pi}@$found_host"
printf '%s\n' "$found_host"
