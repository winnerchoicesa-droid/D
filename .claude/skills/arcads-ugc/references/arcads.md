# Plateforme : casting, réglages, contrôle qualité

Référence pour les étapes 4 à 6 du skill. Les libellés d'interface et les tarifs bougent : ce fichier décrit la **mécanique**, pas le menu du jour. Vérifier les détails sur arcads.ai.

## Ce que fait l'outil

Arcads transforme un script écrit en vidéo « talking head » jouée par un acteur IA, à partir d'une bibliothèque d'acteurs filmés (personnes réelles ayant cédé leur image) dont la voix et le mouvement des lèvres sont regénérés sur le texte fourni. Le flux type : coller le script → choisir l'acteur → choisir la voix et la langue → générer → récupérer le rendu, sous-titrer, monter. Fonctions annexes courantes : aide à l'écriture du script, sous-titres automatiques, traduction, formats/ratios multiples, clonage d'acteur et accès API sur les plans hauts.

## Choisir l'acteur

- **Cohérence avant esthétique** : l'acteur doit ressembler à un client, pas à un mannequin. Un visage trop « pub » tue l'effet UGC.
- **Décor cohérent** avec le script (cuisine, voiture, bureau, extérieur). Une phrase sur la cuisine dite dans un studio blanc sonne faux.
- **Âge et genre** alignés sur l'audience, sauf angle assumé (« mon mari a testé »).
- **Tester deux acteurs opposés** sur le même script : c'est une variable de performance à part entière, pas un détail de goût.
- **Rotation** : réutiliser le même visage sur toutes les créas d'un compte crée de la lassitude publicitaire.

## Voix et langue

- Écouter la voix sur **le** script, pas sur la démo : le débit change avec la ponctuation.
- Ponctuer pour piloter le rythme — un point force une pause, les virgules accélèrent.
- Noms de marque et acronymes : les écrire en **phonétique** dans le script si la prononciation dérape (« Ové-ache » plutôt que « OVH »).
- Marchés multiples : regénérer dans la langue cible avec un acteur natif plutôt que traduire une voix existante.

## Réglages de sortie

- **9:16** pour TikTok, Reels, Shorts, Stories. Prévoir la version 1:1 ou 4:5 seulement si le placement fil d'actualité est acheté.
- **Durée** : 15-25 s pour TikTok, jusqu'à 30 s pour Meta.
- **Sous-titres incrustés**, texte gros, haut du cadre libre (l'UI de la plateforme mange le bas et le haut).
- **Zone de sécurité** : garder le visage et le texte au centre, les bords sont recouverts par l'interface.

## Contrôle qualité (étape 6)

Chaque vidéo passe ces points avant diffusion :

- [ ] Synchro labiale correcte sur toute la durée, en particulier sur la dernière phrase.
- [ ] Aucun artefact sur le visage, les mains, les dents.
- [ ] Débit naturel : ni précipité, ni traînant.
- [ ] Audio sans saturation ni coupure, volume homogène avec le B-roll.
- [ ] Sous-titres synchrones, sans faute, hors zone d'interface.
- [ ] Hook prononcé dans les 3 premières secondes, avant tout élément de marque.
- [ ] Claims conformes et mention IA si requise (`conformite.md`).
- [ ] Nom de fichier au format `angle_hook_acteur_v#`.

Une vidéo qui échoue sur un point se regénère ou se coupe au montage. Elle ne part pas en diffusion « parce que le lot est prêt ».

## Économie des générations

La facturation se fait en crédits par génération, souvent au même prix quelle que soit la durée dans une fourchette large. Conséquences pratiques :

- Verrouiller le script **avant** de générer ; corriger une virgule coûte une génération complète.
- Générer une vidéo test par acteur retenu avant le batch.
- Ne pas raccourcir une vidéo pour économiser : la durée se choisit sur la performance, pas sur le coût.
