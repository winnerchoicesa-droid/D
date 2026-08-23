# Accéder au Pi (Hermes) depuis n'importe quel Mac de la maison

> **La machine s'appelle `saintprex-hub`** (Debian 13), pas `hermes` ni
> `raspberrypi`. Elle était sur `192.168.1.106` le 23/08/2026. Chercher les
> mauvais noms mDNS a coûté une heure de diagnostic : commencer par là.
>
> **Le SSH n'accepte que les clés** — `PasswordAuthentication` est désactivé.
> Sans clé déjà déposée dans `authorized_keys`, aucun mot de passe ne passera,
> et il faut un clavier branché sur le Pi lui-même. Déposer une clé par Mac
> *avant* d'en avoir besoin (section 3) évite de se retrouver bloqué.
>
> **AdGuard Home écoute sur le port 80** de cette machine. Utile pour vérifier
> qu'elle est vivante, mais il ne donne aucun accès au système.

Deux sujets séparés, à traiter dans cet ordre :

1. **Se connecter au Pi** depuis un Mac qui n'est pas le tien.
2. **Réparer l'erreur `[Errno 5] Input/output error`** sur `/mnt/ssd`.

---

## 1. Se connecter depuis le Mac d'Anne-Laure

Ouvre **Terminal** (Cmd+Espace → « Terminal »).

### Le chemin rapide

```bash
ssh pi@hermes.local
```

Remplace `pi` par ton nom d'utilisateur réel sur le Pi, et `hermes.local` par
le hostname réel. Si tu ne les connais pas, passe par le script :

```bash
curl -fsSL https://raw.githubusercontent.com/winnerchoicesa-droid/d/claude/pi-access-shared-mac-mvmcvz/scripts/pi-find.sh -o /tmp/pi-find.sh
bash /tmp/pi-find.sh
```

Il enchaîne trois méthodes en affichant sa progression :

1. **Bonjour** (`dns-sd -B _ssh._tcp`) — liste les machines qui annoncent un
   service SSH. Rapide quand ça marche, mais une liste vide ne prouve rien :
   Raspberry Pi OS publie son nom d'hôte en mDNS sans forcément publier
   l'enregistrement de service `_ssh._tcp`, et un Mac n'y apparaît que si
   « Connexion à distance » est activée dans Réglages Système → Général →
   Partage.
2. **noms mDNS** habituels : `hermes.local`, `raspberrypi.local`, …
3. **balayage ARP** — ping du `/24` local par paquets de 32, puis filtrage de la
   table ARP sur les préfixes MAC de la Raspberry Pi Foundation (`b8:27:eb`,
   `dc:a6:32`, `e4:5f:01`, `2c:cf:67`, `d8:3a:dd`, `28:cd:c1`).

Compter une vingtaine de secondes au total. Si tu veux juste la liste Bonjour
sans le reste, la commande native suffit :

```bash
dns-sd -B _ssh._tcp local.   # Ctrl+C pour arrêter
```

Et si tu veux uniquement le balayage ARP, sans script :

```bash
ip=$(ipconfig getifaddr en0); sub=${ip%.*}
for i in $(seq 1 254); do ping -c1 -W300 $sub.$i >/dev/null 2>&1 & done; wait
arp -a | grep -iE 'b8:27:eb|dc:a6:32|e4:5f:01|2c:cf:67|d8:3a:dd|28:cd:c1'
```

Pour chercher **et** se connecter directement :

```bash
bash /tmp/pi-find.sh --ssh pi
```

### Attendre que le Pi revienne après un redémarrage

```bash
curl -fsSL "https://raw.githubusercontent.com/winnerchoicesa-droid/d/claude/pi-access-shared-mac-mvmcvz/scripts/pi-wait.sh?v=$(date +%s)" -o /tmp/pi-wait.sh
bash /tmp/pi-wait.sh
```

Le script boucle sur la résolution mDNS puis le balayage ARP, et s'arrête dès
que le Pi répond. Un cycle dure une quinzaine de secondes.

Compter 60 à 90 s pour un démarrage normal. Si le SSD est déclaré dans
`/etc/fstab` et ne répond plus, systemd attend son délai de montage avant
d'abandonner : le démarrage peut prendre 2 à 3 minutes de plus.

> **Lance-le avec `bash`, pas en collant la boucle dans zsh.** zsh interactif
> signale la fin de chaque tâche en arrière-plan, ce qui produit une ligne
> `exit 2` par ping — 254 par cycle. Ce ne sont pas des erreurs, juste
> l'absence de réponse, mais elles noient la sortie.

### Si aucun MAC Raspberry Pi n'apparaît

Le balayage ARP ne reconnaît que les préfixes MAC de la fondation. Un Pi
derrière un adaptateur USB Ethernet, une carte Wi-Fi tierce ou un MAC forcé
passera au travers. Dans ce cas, cherche plutôt qui écoute en SSH :

```bash
curl -fsSL "https://raw.githubusercontent.com/winnerchoicesa-droid/d/claude/pi-access-shared-mac-mvmcvz/scripts/pi-scan-ssh.sh?v=$(date +%s)" -o /tmp/pi-scan-ssh.sh
bash /tmp/pi-scan-ssh.sh
```

Le script balaie le `/24`, teste le port 22 sur chaque adresse vivante et
affiche la bannière SSH renvoyée — une bannière `OpenSSH ... Debian` trahit un
Linux, donc très probablement le Pi.

La version en une commande, sans téléchargement :

```bash
me=$(ipconfig getifaddr en0)
for ip in $(arp -a -n | sed -n 's/.*(\([0-9.]*\)).*/\1/p' | grep -vE '\.255$|^224\.' | grep -v "^$me$" | sort -t. -k4 -n -u); do
  nc -z -G1 "$ip" 22 2>/dev/null && echo "$ip  → SSH ouvert"
done
```

Si **rien** n'écoute sur le port 22, le Pi est éteint, planté, ou sur un autre
réseau. La liste des baux DHCP de la box tranche : elle affiche aussi les
appareils actuellement hors ligne, avec leur nom d'hôte et leur dernière IP.

> Note sur le cache : `raw.githubusercontent.com` sert une version en cache
> pendant quelques minutes. Ajoute `?v=$(date +%s)` à l'URL pour forcer la
> version à jour.

### Si tu n'as ni le nom ni l'IP

L'interface de la box/routeur (souvent `http://192.168.1.1`) liste les
appareils connectés ; cherche « raspberry » dans les noms d'hôtes.

### Si SSH demande un mot de passe et que tu ne l'as pas

Ta clé SSH est restée sur ton Mac. Deux options :
- clavier + écran branchés directement sur le Pi ;
- si tu as accès à ton Mac à distance (iCloud, Time Machine, un backup), tu
  peux récupérer `~/.ssh/id_ed25519` — mais **ne la copie pas** sur une machine
  qui n'est pas à toi. Préfère la section 3.

---

## 2. Réparer l'erreur `Errno 5` sur `/mnt/ssd`

`Errno 5 = EIO` : erreur d'entrée/sortie **matérielle**, pas un bug du bot.
C'est pour ça que `/reset` échoue avec exactement le même message — le reset
écrit lui aussi dans `/mnt/ssd/hermes/platforms/pairing/telegram-approved.json`.

Causes, par fréquence décroissante :

| Cause | Signe dans `dmesg` |
|---|---|
| FS remonté en lecture seule après un reset USB | `EXT4-fs ... Remounting filesystem read-only` |
| Sous-tension de l'alim → reset du port USB | `usb ... reset`, `vcgencmd get_throttled` ≠ `0x0` |
| Câble ou adaptateur USB-SATA défaillant | `usb ... disconnect`, erreurs `uas_` |
| SSD en fin de vie | compteurs SMART réalloués |

**Cas vécu le 23/08/2026.** Un disque avait été remplacé. Le montage `/mnt/ssd`
est devenu fantôme : le noyau répondait `EIO` sur un périphérique qui n'existait
plus, et le bot échouait en boucle. Débrancher puis rebrancher le SSD à chaud
n'a rien changé — un montage mort ne se répare pas à chaud. Ce qui a fonctionné :
couper l'alimentation, rebrancher le disque, redémarrer. Le bot est reparti seul.

Réflexe à retenir : après toute manipulation de disque sur cette machine,
**redémarrer**, ne pas se contenter de rebrancher.

Depuis la session SSH, sur le Pi :

```bash
curl -fsSL https://raw.githubusercontent.com/winnerchoicesa-droid/d/claude/pi-access-shared-mac-mvmcvz/scripts/pi-ssd-check.sh -o /tmp/pi-ssd-check.sh
sudo bash /tmp/pi-ssd-check.sh
```

Le diagnostic **n'écrit rien**. Pour tenter la réparation (arrêt du service,
démontage, `fsck`, remontage), avec confirmation demandée :

```bash
sudo bash /tmp/pi-ssd-check.sh --repair
```

Adapte le nom du service si nécessaire :

```bash
SERVICE=hermes-bot sudo -E bash /tmp/pi-ssd-check.sh --repair
```

Le plus souvent, un simple `sudo reboot` remonte le SSD proprement et le bot
repart — mais si `get_throttled` signale une sous-tension, ça reviendra tant
que l'alimentation n'est pas corrigée (alim officielle 5V/3A minimum, ou SSD
sur hub auto-alimenté).

---

## 3. Ouvrir l'accès à tous les Macs de la maison, proprement

**Une clé par machine.** Ne partage jamais une clé privée entre deux Macs.

Sur chaque Mac (celui d'Anne-Laure inclus) :

```bash
ssh-keygen -t ed25519 -C "mac-anne-laure"
ssh-copy-id pi@hermes.local
```

Puis un alias pour ne plus retaper l'adresse — sur chaque Mac, dans
`~/.ssh/config` :

```
Host hermes
    HostName hermes.local
    User pi
    IdentityFile ~/.ssh/id_ed25519
```

Ensuite : `ssh hermes`.

Pour retirer l'accès d'un Mac plus tard, il suffit de supprimer la ligne
correspondante dans `/home/pi/.ssh/authorized_keys` sur le Pi.

## 3 bis. Time Machine et Nextcloud sur le Pi

### Les comptes Samba n'ont pas de tiret

macOS pré-remplit le champ « Nom » de la fenêtre de connexion avec le nom du
compte **local** du Mac — `anne-laure`. Les comptes Samba créés sur le Pi
s'appellent `daniel`, `annelaure`, `eva`, **sans tiret**. Tant que le champ
n'est pas corrigé, aucun mot de passe ne fonctionnera, et l'erreur ne dit pas
que c'est l'identifiant qui est faux.

Les mots de passe Samba sont saisis à l'aveugle par `smbpasswd` et ne sont
stockés nulle part en clair. Pour en redéfinir un :

```bash
ssh -t hermes 'sudo smbpasswd -a annelaure'
```

Deux saisies identiques. `pdbedit -L` liste les comptes existants :

```bash
ssh hermes 'sudo pdbedit -L'
```

### Les partitions Time Machine

| Partition | Étiquette | Taille | Point de montage | Partage Samba |
|---|---|---|---|---|
| `sdd1` | `daniel` | 570 Go | `/mnt/tm/daniel` | `TM-daniel` |
| `sdd2` | `eva` | 200 Go | `/mnt/tm/eva` | `TM-eva` |
| `sdd3` | `annelaure` | 158 Go | `/mnt/tm/annelaure` | `TM-annelaure` |

Chacune est en `chmod 700` et appartient à son utilisateur : personne ne lit la
sauvegarde d'un autre. Toutes sont déclarées dans `/etc/fstab` avec `nofail`.

### Nextcloud

Il tourne en conteneurs sous `/home/daniel/famille/docker-compose.yml` et
répond sur **le port 8081** :

```
http://192.168.1.106:8081
```

Les quatre conteneurs `famille-*` (nextcloud, cron, db, redis) se sont arrêtés
avec le code 255 pendant l'incident disque du 23/08 — dégât collatéral, aucune
corruption. Pour les relancer :

```bash
ssh hermes 'cd /home/daniel/famille && sudo docker compose up -d'
```

Lister les comptes Nextcloud, qui sont indépendants de ceux du Pi :

```bash
ssh hermes 'sudo docker exec -u www-data famille-nextcloud php occ user:list'
```

## 4. Atteindre le tableau de bord Hermes depuis un Mac

Hermes expose une interface web, mais elle n'écoute **que sur le Pi lui-même** :

```
hermes dashboard --host 127.0.0.1 --port 9119 --no-open --skip-build
```

Aucun balayage réseau ne la trouvera, c'est voulu. Un tableau de bord lié à
`127.0.0.1` n'a en général pas de page de connexion : le rebasculer sur
`0.0.0.0` donnerait le contrôle de l'agent à tout appareil du réseau, invités
du Wi-Fi compris. On passe donc par un tunnel SSH, qui réutilise la connexion
chiffrée déjà en place et n'ouvre rien.

### Tunnel ponctuel

```bash
ssh -N -L 9119:127.0.0.1:9119 hermes
```

La commande ne rend pas la main tant que le tunnel vit. Laisser la fenêtre
ouverte, puis aller sur `http://localhost:9119`.

### Tunnel permanent

Ajouter la ligne `LocalForward` au bloc `Host hermes` de `~/.ssh/config` :

```
Host hermes
    HostName 192.168.1.106
    User daniel
    IdentityFile ~/.ssh/id_pi
    ServerAliveInterval 60
    LocalForward 9119 127.0.0.1:9119
```

Le tunnel s'ouvre alors avec chaque session `ssh hermes`, sans commande
supplémentaire.

### Tunnel permanent, sans Terminal ouvert

`LocalForward` suppose une session SSH vivante : dès que la fenêtre se ferme,
l'application Hermes Agent affiche « ne parvient pas à se connecter au serveur ».
Pour un poste qui n'est pas celui d'un administrateur, il faut un service qui
tienne le tunnel tout seul.

Sur le Mac, créer `~/Library/LaunchAgents/com.hermes.tunnel.plist` :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.hermes.tunnel</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/ssh</string>
    <string>-N</string>
    <string>-o</string><string>ExitOnForwardFailure=yes</string>
    <string>-o</string><string>ServerAliveInterval=30</string>
    <string>-o</string><string>ServerAliveCountMax=3</string>
    <string>-o</string><string>StrictHostKeyChecking=accept-new</string>
    <string>-i</string><string>/Users/&lt;utilisateur&gt;/.ssh/id_pi</string>
    <string>-L</string><string>9119:127.0.0.1:9119</string>
    <string>daniel@192.168.1.106</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>ThrottleInterval</key><integer>10</integer>
  <key>StandardErrorPath</key><string>/tmp/hermes-tunnel.err</string>
</dict>
</plist>
```

Le chemin de la clé et l'utilisateur distant sont écrits en dur : `launchd`
démarre avec un environnement minimal, mieux vaut ne pas dépendre de
`~/.ssh/config`. `KeepAlive` relance le tunnel s'il tombe, `RunAtLoad` l'ouvre
à l'ouverture de session.

Activer et vérifier :

```bash
launchctl unload ~/Library/LaunchAgents/com.hermes.tunnel.plist 2>/dev/null
launchctl load   ~/Library/LaunchAgents/com.hermes.tunnel.plist
lsof -nP -iTCP:9119 -sTCP:LISTEN
```

Deux lignes `ssh … (LISTEN)` signifient que c'est en place. En cas d'échec, la
cause est dans `/tmp/hermes-tunnel.err`.

### Ne pas confondre avec les autres services

Le Pi héberge plusieurs choses qui répondent en HTTP. Deux fausses pistes
coûteuses lors du diagnostic du 23/08 :

| Port | Ce que c'est | Ce que ce n'est pas |
|---|---|---|
| 80 | AdGuard Home | pas Hermes |
| 4100 | `casa-outeiro-whatsapp-bot` (`node src/server.js`) | pas Hermes non plus |
| 9119 | **le tableau de bord Hermes**, sur `127.0.0.1` | invisible depuis le réseau |

Pour identifier un port inconnu, `curl http://<ip>:<port>/health` répond
souvent avec le nom du service, et `sudo ss -tlnp` donne le processus.

### Accès depuis l'extérieur de la maison

N'ouvre **pas** le port 22 sur la box. Installe [Tailscale](https://tailscale.com)
sur le Pi et sur chaque Mac, avec le même compte :

```bash
# sur le Pi
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```

Le Pi devient joignable par son nom Tailscale depuis n'importe quel appareil du
réseau, où qu'il soit, sans redirection de port ni exposition sur Internet.
