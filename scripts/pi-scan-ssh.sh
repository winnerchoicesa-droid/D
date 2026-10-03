#!/usr/bin/env bash
# Liste les machines du reseau local qui ecoutent sur le port 22 (SSH).
# Utile quand le Pi n'est pas identifiable par son MAC : carte reseau tierce,
# adaptateur USB Ethernet, MAC aleatoire...
#
#   ./pi-scan-ssh.sh
#
# A lancer depuis un Mac. Ne modifie rien.

set -uo pipefail

PORT="${PORT:-22}"

iface=$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')
myip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)
[ -n "${myip:-}" ] || { echo "Impossible de determiner l'IP locale." >&2; exit 1; }
subnet="${myip%.*}"

echo "Ce Mac : $myip (${iface:-en0})"
echo "Peuplement de la table ARP sur $subnet.0/24..."
n=1
while [ "$n" -le 254 ]; do
  end=$((n + 31)); [ "$end" -gt 254 ] && end=254
  i=$n
  while [ "$i" -le "$end" ]; do
    ping -c1 -W300 "$subnet.$i" >/dev/null 2>&1 &
    i=$((i + 1))
  done
  wait
  printf '.'
  n=$((end + 1))
done
echo

ips=$(arp -a -n 2>/dev/null \
  | sed -n 's/.*(\([0-9.]*\)).*/\1/p' \
  | grep -vE '\.255$|^224\.|^239\.' \
  | grep -v "^${myip}$" \
  | sort -t. -k4 -n -u)

count=$(printf '%s\n' "$ips" | grep -c . || true)
echo "Test du port $PORT sur $count adresses..."
echo

found=0
for ip in $ips; do
  if nc -z -G 1 "$ip" "$PORT" 2>/dev/null; then
    # Nom mDNS si disponible (arp -a sans -n tente une resolution)
    name=$(arp -a 2>/dev/null | awk -v t="($ip)" '$2==t {print $1; exit}')
    [ "$name" = "?" ] && name=""
    banner=$( (printf '\n'; sleep 1) | nc -G 2 "$ip" "$PORT" 2>/dev/null | head -1 | tr -d '\r' )
    printf '  %-15s SSH ouvert  %s  %s\n' "$ip" "${name:-}" "${banner:-}"
    found=$((found + 1))
  fi
done

echo
if [ "$found" -eq 0 ]; then
  echo "Aucune machine n'ecoute sur le port $PORT."
  echo "Le Pi est probablement eteint, plante, ou sur un autre reseau."
  echo "Verifie la liste des baux DHCP dans l'interface de la box."
else
  echo "$found machine(s) trouvee(s). Une banniere contenant 'Raspbian',"
  echo "'Debian' ou 'OpenSSH_9' cote Linux est un bon indice."
  echo "Pour tester : ssh pi@<adresse>"
fi
