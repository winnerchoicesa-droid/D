# Accéder au Pi (Hermes) depuis n'importe quel Mac de la maison

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

Il essaie les noms mDNS habituels, puis balaie le réseau local et repère les
adresses dont le préfixe MAC appartient à la Raspberry Pi Foundation
(`b8:27:eb`, `dc:a6:32`, `e4:5f:01`, `2c:cf:67`, `d8:3a:dd`, `28:cd:c1`).

Pour chercher **et** se connecter directement :

```bash
bash /tmp/pi-find.sh --ssh pi
```

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
