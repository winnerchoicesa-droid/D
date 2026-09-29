#!/usr/bin/env python3
"""Contrôle rapide de Home Assistant (HA) et de l'intégration Philips Hue.

À exécuter depuis une machine qui atteint le Raspberry Pi (réseau de la maison,
VPN ou URL Nabu Casa) :

    export HA_URL="http://homeassistant.local:8123"
    export HA_TOKEN="<jeton d'accès longue durée : Profil > Sécurité > Jetons>"
    ./check-ha.py

Référence API : https://developers.home-assistant.io/docs/api/rest/
"""
import json
import os
import sys
import urllib.error
import urllib.request

HA_URL = os.environ.get("HA_URL", "").rstrip("/")
HA_TOKEN = os.environ.get("HA_TOKEN", "")
if not HA_URL or not HA_TOKEN:
    sys.exit("HA_URL et HA_TOKEN doivent être définis (voir l'en-tête du script).")


def api(path, method="GET", timeout=15):
    req = urllib.request.Request(
        f"{HA_URL}/api{path}",
        method=method,
        headers={"Authorization": f"Bearer {HA_TOKEN}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.load(resp)


def section(title):
    print(f"\n== {title}")


ok = True

section("1. API HA joignable")
try:
    print("OK :", api("/").get("message"))
except (urllib.error.URLError, OSError) as exc:
    sys.exit(f"ECHEC : l'API ne répond pas ({exc}). Vérifier l'URL, le jeton ou si HA est arrêté.")

section("2. Version / état")
cfg = api("/config")
print("version :", cfg.get("version"))
print("état    :", cfg.get("state"))
print("zone    :", cfg.get("location_name"))
if cfg.get("state") != "RUNNING":
    ok = False

section("3. Vérification de la configuration YAML")
try:
    chk = api("/config/core/check_config", method="POST", timeout=60)
    print("résultat:", chk.get("result"))
    if chk.get("errors"):
        ok = False
        print(chk["errors"])
except urllib.error.HTTPError as exc:
    print(f"(endpoint indisponible, HTTP {exc.code} : vérifier via Paramètres > Système > Réparations)")

states = api("/states")

section("4. Lumières et Philips Hue")
lights = [s for s in states if s["entity_id"].startswith("light.")]
hue = [s for s in lights
       if "hue" in s["entity_id"] or "hue" in json.dumps(s.get("attributes", {})).lower()]
unavailable = [s["entity_id"] for s in lights if s["state"] == "unavailable"]
print("lumières totales :", len(lights))
print("lumières Hue     :", len(hue))
print("indisponibles    :", ", ".join(unavailable) if unavailable else "aucune")
if unavailable:
    ok = False

section("5. Automatisations désactivées ou indisponibles")
bad = [(s["entity_id"], s["state"]) for s in states
       if s["entity_id"].startswith("automation.") and s["state"] != "on"]
for eid, st in bad or []:
    print(f"{eid} -> {st}")
if not bad:
    print("aucune")

section("6. Garde-fou Saint-Prex (baisse de lumière bloquée avant 22h)")
guard = [s for s in states if s["entity_id"].startswith("automation.saint_prex")]
for s in guard:
    print(f'{s["entity_id"]} -> {s["state"]} (dernier déclenchement : {s["attributes"].get("last_triggered")})')
if not guard:
    print("non installé : voir saint_prex_lumiere.yaml")

print("\nRésultat global :", "OK" if ok else "À VÉRIFIER")
sys.exit(0 if ok else 1)
