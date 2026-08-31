# Serveur Dell — site de Parada

Fiche d'inventaire établie à partir des photos des faces arrière et avant du
châssis (31.08.2026). Aucun relevé logiciel n'a encore été effectué sur la
machine.

## Identification

| Champ | Valeur | Source |
|---|---|---|
| Site | Parada | déclaré par le propriétaire |
| Constructeur | Dell | étiquette châssis |
| Modèle réglementaire | E35S / type E35S001 | étiquette réglementaire |
| Modèle commercial | **PowerEdge T330** (tour) | sérigraphie en façade (photo) |
| Lieu de fabrication | Pologne | étiquette réglementaire |
| Entité Dell | Raheen Business Park, Limerick, Irlande | étiquette châssis |
| **Service Tag (n° de série)** | **à compléter** — relevable via le panneau LCD en façade | — |
| Express Service Code | à compléter | — |

## Alimentation

| Champ | Valeur |
|---|---|
| Tension d'entrée | 100–240 V~ |
| Courant | 5,5–3,0 A |
| Fréquence | 50/60 Hz |
| P/N bloc d'alimentation | 0TK5R9 (CN-0TK5R9-IPS00-81A-022D-A03) |
| Redondance | 1 bloc installé, 2e emplacement présent |

## Autres références relevées

Ces codes sont des **numéros de pièce Dell (DP/N)**, pas des numéros de série :

- `9YNMP A00` — étiquette signalétique / sécurité
- `YFR86 A00` — étiquette réglementaire
- `0TK5R9` — bloc d'alimentation
- étiquette code-barres près des connecteurs PCIe — illisible sur la photo

## Configuration observée

Face avant :
- 8 baies 2,5" hot-swap — **2 occupées, 6 libres**
- 3 baies 5,25" (caches en place)
- Panneau LCD de diagnostic + boutons `<` `✓` `>`
- 1 port USB 2.0 + 1 port USB 3.0 en façade
- Cadre (bezel) absent

Face arrière :
- Carte 4 ports (connecteurs à leviers bleus) occupant l'emplacement PCIe bas
- 3 emplacements PCIe libres (caches en place)
- Ports USB, 2 ports réseau, port série, VGA

## Plafonds de la plateforme

| Élément | Maximum du T330 |
|---|---|
| Processeur | Xeon E3-1200 v5/v6 — **4 cœurs / 8 threads**, socket LGA1151 |
| Mémoire | **64 Go** (4 slots, DDR4-2400 UDIMM ECC, 16 Go/barrette) |
| Stockage | 8 × 2,5" ou 8 × 3,5" |
| Extension | 4 emplacements PCIe 3.0 |

Ces deux plafonds — 64 Go de RAM et 4 cœurs — sont imposés par le chipset C236
et ne sont pas contournables.

## Arbitrage : garder ou remplacer

**Garder** si l'usage est NAS/sauvegardes, Proxmox avec 2 à 5 VM légères,
serveur de fichiers, domotique, Nextcloud, quelques conteneurs. La machine
reste adaptée et dispose de 6 baies et 3 slots PCIe libres.

Améliorations pertinentes dans le châssis actuel (ordres de grandeur en
occasion, **non vérifiés** — à confirmer au moment de l'achat) :

| Amélioration | Coût indicatif |
|---|---|
| RAM à 64 Go (4 × 16 Go UDIMM ECC 2400) | ~80–150 € |
| CPU vers E3-1230 / E3-1270 v6 | ~50–100 € |
| SSD SATA entreprise dans les baies libres | ~40–80 €/To |
| Carte 10 GbE (Intel X520 / X710) | ~30–60 € |
| Second bloc d'alimentation (redondance) | variable |

**Remplacer** si le besoin dépasse 64 Go de RAM ou 4 cœurs : virtualisation
sérieuse, base de données lourde, nombreux conteneurs. Le T330 n'est pas une
base viable pour de l'IA locale (pas d'alimentation GPU dédiée, PCIe 3.0,
4 cœurs).

**Facteur électricité** (estimations) : ~55–70 W au repos en fonctionnement
continu, soit ~500–600 kWh/an (~110–150 €/an au Portugal). Un mini-PC moderne
assure les mêmes fonctions NAS/domotique à 8–15 W. L'écart sur 5 ans finance
un remplacement — mais fait perdre l'ECC et les baies hot-swap.

**Décision en attente** : dépend de l'usage prévu et de la configuration
actuelle (CPU, barrettes installées, slots libres), non relevés à ce jour.

## Reste à faire

- [ ] Relever le **Service Tag** (7 caractères alphanumériques) via le
      **panneau LCD en façade** : bouton `✓` → **View** → **Service Tag**.
      À défaut : BIOS (F2 → System Information), iDRAC, ou depuis l'OS —
      Linux `sudo dmidecode -s system-serial-number`,
      Windows `wmic bios get serialnumber`.
- [ ] Relever la configuration actuelle avant tout achat :
      `sudo dmidecode -t system -t processor -t memory`, `lscpu`, `free -h`
      (le nombre de slots mémoire libres change entièrement le coût d'un
      passage à 64 Go).
- [ ] Définir l'usage cible pour trancher garder / remplacer
- [ ] Vérifier le statut de garantie sur dell.com/support avec ce Service Tag
- [ ] Identifier le contrôleur de stockage (PERC H330/H730 ?) et l'état RAID
