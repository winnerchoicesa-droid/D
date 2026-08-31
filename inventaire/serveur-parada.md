# Serveur Dell — site de Parada

Fiche d'inventaire établie à partir des étiquettes visibles sur la face arrière
du châssis (photo du 31.08.2026).

## Identification

| Champ | Valeur | Source |
|---|---|---|
| Site | Parada | déclaré par le propriétaire |
| Constructeur | Dell | étiquette châssis |
| Modèle réglementaire | E35S / type E35S001 | étiquette réglementaire |
| Modèle commercial | PowerEdge T330 (tour) | correspondance E35S → T330 |
| Lieu de fabrication | Pologne | étiquette réglementaire |
| Entité Dell | Raheen Business Park, Limerick, Irlande | étiquette châssis |
| **Service Tag (n° de série)** | **à compléter — non lisible sur la photo** | — |
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

- Carte 4 ports (connecteurs à leviers bleus) occupant l'emplacement PCIe bas
- 3 emplacements PCIe libres (caches en place)
- Bloc arrière : ports USB, 2 ports réseau, port série, VGA

## Reste à faire

- [ ] Relever le **Service Tag** (7 caractères alphanumériques) :
      languette d'information extractible en façade, sous la baie de disques,
      ou étiquette sur le dessus/côté du châssis.
      À défaut : BIOS (F2 → System Information), iDRAC, ou depuis l'OS —
      Linux `sudo dmidecode -s system-serial-number`,
      Windows `wmic bios get serialnumber`.
- [ ] Vérifier le statut de garantie sur dell.com/support avec ce Service Tag
- [ ] Relever la configuration interne (CPU, RAM, disques, contrôleur RAID)
