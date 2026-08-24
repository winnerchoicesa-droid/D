# D — configuration Claude Code

## Ce que contient ce dépôt

- `.claude/hooks/session-start.sh` — clone/met à jour [mattpocock/skills](https://github.com/mattpocock/skills) et lie les skills au démarrage d'une session distante.
- `.claude/skills/arcads-ugc/` — skill de production de publicités UGC avec acteurs IA (Arcads) : brief, angles, scripts et hooks, casting, génération, contrôle qualité, test créa, conformité.

## Utiliser le skill UGC

Il se déclenche tout seul sur une demande de pub UGC, de script TikTok/Reels/Meta ou de déclinaison de hooks. On peut aussi l'appeler à la main :

```
/arcads-ugc
```

Le skill demande d'abord le brief en 7 points (produit, audience, douleur, offre, preuve, CTA, contraintes), puis déroule le cycle jusqu'au plan de test.
