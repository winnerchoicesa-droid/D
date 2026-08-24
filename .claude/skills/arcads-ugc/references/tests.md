# Tester et itérer

Référence pour les étapes 8 et 9 du skill.

## Nommage

`angle_hook_acteur_v#` — par exemple `objection_prix-cher_sofia_v2`. Sans ce nommage, les rapports de la régie publicitaire ne disent rien : on ne saura pas si c'est le hook ou l'acteur qui a gagné.

## Structure de test

- Une campagne, un ensemble de publicités, **toutes les créas du lot dedans** : laisser l'algorithme répartir, plutôt que d'isoler chaque créa dans son propre ensemble (les petits budgets fragmentés ne sortent jamais de la phase d'apprentissage).
- Ciblage large : le test porte sur la créa, pas sur l'audience.
- Budget quotidien qui permet d'atteindre au moins **1 000 impressions par créa** en 3 jours ; sinon réduire le nombre de créas du lot, pas le budget.
- Une seule variable change entre deux créas comparées.

## Métriques, dans l'ordre de lecture

1. **Taux de rétention à 3 s** — juge le hook. En dessous du repère du compte, le hook est mort, le reste de la vidéo n'a pas été vu.
2. **Taux de clic (CTR)** — juge le corps et le CTA.
3. **Coût par acquisition / ROAS** — juge la créa entière. Seule métrique qui décide de la mise à l'échelle.

Décision type après 3 jours ou 1 000 impressions par créa : couper le tiers inférieur au CPA, laisser tourner le milieu, décliner le tiers supérieur.

## Décliner un gagnant

Ne changer **qu'une** variable :

- même script, nouvel acteur ;
- même acteur, nouveaux hooks (le plus rentable) ;
- même hook, corps réécrit sur un autre bénéfice ;
- même vidéo, nouveau montage (B-roll, texte à l'écran, musique).

Une déclinaison qui change deux variables produit un résultat ininterprétable.

## Journal de cycle

Tenir une ligne par créa : nom, angle, hook, acteur, dépense, rétention 3 s, CTR, CPA, décision. Après trois cycles, ce journal dit quels **types** de hooks et quels **profils** d'acteur marchent sur le compte — c'est l'actif réel, plus que les vidéos elles-mêmes.
