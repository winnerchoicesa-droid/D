# Maison de Saint-Prex – contrôle Home Assistant et lumière Hue

Ce dossier a été préparé depuis un environnement cloud **sans accès** au réseau de la maison.
Rien n'a été modifié sur l'installation réelle : les deux fichiers ci-dessous sont à appliquer sur place.

| Fichier | Rôle |
|---|---|
| `check-ha.py` | Vérifie que Home Assistant répond, que la configuration est valide, que les lumières Hue sont disponibles et qu'aucune automatisation n'est en erreur. |
| `saint_prex_lumiere.yaml` | Paquet HA : la baisse automatique de la lumière est bloquée entre 06h00 et 22h00, puis autorisée. Heure modifiable dans l'UI. |

## 1. Contrôler que Home Assistant marche

```bash
export HA_URL="http://homeassistant.local:8123"   # ou l'URL Nabu Casa
export HA_TOKEN="<jeton longue durée>"            # Profil > Sécurité > Jetons d'accès longue durée
./check-ha.py
```

Contrôles complémentaires dans l'interface : Paramètres > Système > Réparations (aucune alerte),
Paramètres > Appareils et services > Philips Hue (pont « Connecté »), Paramètres > Système > Journaux.

## 2. Arrêter la baisse de lumière avant 22h

Deux cas, selon **qui** baisse la lumière :

1. **Une automatisation Home Assistant** (ou l'intégration Adaptive Lighting) : installer le paquet
   `saint_prex_lumiere.yaml` et remplacer `automation.baisse_lumiere_soir` par l'identifiant réel.
   Pour Adaptive Lighting, cibler plutôt `switch.adaptive_lighting_<nom>` avec `switch.turn_off` / `switch.turn_on`.
2. **Une automatisation native Hue** (application Hue : « Lumière naturelle », « Coucher », minuteries) :
   HA ne peut pas la modifier. Dans l'app Hue : Automatisations > l'automatisation concernée > régler
   l'heure de début sur 22:00, ou la désactiver et laisser HA gérer.

## Limites

- L'identifiant de l'automatisation existante et le type de pilotage (HA ou app Hue) n'ont pas pu être vérifiés d'ici.
- Le script suppose `python3` sur la machine qui l'exécute.
