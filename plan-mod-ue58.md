# Plan : importer la police de GTA V, du RP et le bac à sable de Garry's Mod dans mon jeu UE 5.8

> **Comment l'utiliser**
> 1. Ouvre PowerShell **dans le dossier de ton projet Unreal** (celui qui contient le `.uproject`), puis lance `claude`.
> 2. Tape d'abord ces deux commandes (une par une) pour installer les skills universal-modder :
>    ```
>    /plugin marketplace add rehan-remade/universal-modder
>    /plugin install universal-modder@universal-modder
>    ```
> 3. Colle **tout le texte sous la ligne** ci-dessous dans Claude et appuie sur Entrée.
>
> Claude te posera quelques questions au début, puis avancera phase par phase. Il s'arrête pour te demander ton accord avant d'installer un logiciel ou de toucher à un dossier de jeu.

---

Tu travailles sur mon jeu Unreal Engine 5.8, un projet **perso et privé** : rien ne sera publié ni distribué. Le dossier courant est la racine du projet (là où se trouve le `.uproject`). Je veux trois choses :
- **A.** la police de GTA V (véhicules, policiers, système d'étoiles et de poursuite) ;
- **B.** des systèmes de type GTA RP / FiveM (métiers, inventaire, argent, interactions) ;
- **C.** le bac à sable de Garry's Mod (menu de spawn, physgun, toolgun, undo) et ses props.

Utilise les skills du plugin universal-modder quand elles s'appliquent : `mod-any-game` (et sa fiche `references/engines/unreal.md`), `game-recon`, `reverse-engineering`, `asset-pipeline`, `mashup-mods` (Pattern 1 : porter le contenu). Si le serveur MCP Unreal est connecté (plugin MCP intégré à UE 5.8), utilise-le pour agir dans l'éditeur. Sinon, utilise le Python de l'éditeur (`UnrealEditor-Cmd.exe <projet>.uproject -run=pythonscript -script=<fichier>.py`).

## Règles

- **Demande-moi avant** d'installer un logiciel, d'écrire dans un dossier de jeu ou de lancer un jeu. Lire les fichiers des jeux sans les modifier est autorisé.
- **Ne modifie jamais** les fichiers d'installation de GTA V ou de Garry's Mod. Copie ce dont tu as besoin dans `D:\` ou à côté du projet, dans un dossier `_extraction\` (demande-moi où).
- Ne lance jamais GTA Online, et n'interagis avec aucun service en ligne des jeux.
- Ne contourne aucun chiffrement (ressources FiveM « escrow », DRM). Si une ressource est chiffrée, passe-la et dis-le-moi.
- Avant de toucher au projet, vérifie qu'il est sous Git. Sinon, propose `git init` et un premier commit. **Commit à la fin de chaque phase** avec un message clair.
- Garde un journal dans `_extraction\JOURNAL.md` : ce qui a été fait, les versions des outils, les chemins, les problèmes rencontrés et leurs solutions.
- Si une étape échoue deux fois de la même manière, arrête-toi et explique-moi le problème au lieu d'insister.
- Vérifie chaque résultat par une preuve (une capture d'écran de l'éditeur, un log, la liste des assets créés), pas en supposant que ça a marché.
- Parle-moi en français.

## Phase 0 : questions et inventaire (ne rien installer)

1. Pose-moi ces questions en une seule fois :
   - **C++ ou Blueprint** pour les systèmes ? (recommande C++ avec des Blueprints enfants si le projet a un dossier `Source\`) ;
   - **solo ou multijoueur** ? (si multijoueur, tout doit être répliqué dès le départ) ;
   - quels véhicules et quels policiers je veux en priorité (proposition par défaut : `police`, `police2`, `police3`, `policeb`, `polmav`, `s_m_y_cop_01`, `s_f_y_cop_01`) ;
   - quels props de Garry's Mod (par défaut : un lot de `models/props_c17`, `props_junk`, `props_borealis`, `props_wasteland`) ;
   - est-ce que j'ai des ressources FiveM à porter, et où elles sont.
2. Trouve tout seul et liste :
   - le `.uproject`, la version exacte du moteur, la présence de `Source\`, les plugins actifs (dont MCP) ;
   - l'installation de GTA V et de Garry's Mod (`um scan`, registre Steam/Epic/Rockstar, `libraryfolders.vdf`) ;
   - les outils déjà présents : Blender (version), addons Sollumz et SourceIO, CodeWalker, .NET SDK, Python, Git, Visual Studio.
3. Écris le plan détaillé et la liste de ce qu'il faut installer dans `_extraction\PLAN.md`, puis **attends mon feu vert**.

## Phase 1 : outils

Après mon accord, installe ce qui manque (winget si possible, sinon téléchargement depuis le **dépôt ou le site officiel** uniquement) :
- **Blender** (la version la plus récente supportée par Sollumz et SourceIO) ;
- **Sollumz** (addon Blender pour les formats GTA V : `.ydr`, `.yft`, `.ydd`, `.ytd`), depuis github.com/Skylumz/Sollumz ;
- **SourceIO** (addon Blender qui lit directement les `.mdl`, `.vtf` et `.vpk` de Source), depuis github.com/REDxEYE/SourceIO ;
- **CodeWalker** (lecture des archives `.rpf` de GTA V), depuis github.com/dexyfex/CodeWalker ;
- le **.NET SDK** si l'étape d'extraction automatique (phase 2) en a besoin.

Active les addons dans Blender en ligne de commande et vérifie qu'ils se chargent (`blender -b --python-expr ...`). Lis les opérateurs réellement exposés par les versions installées (`dir(bpy.ops.sollumz)`, `dir(bpy.ops.sourceio)`) au lieu de deviner leurs noms.

## Phase 2 : extraction des assets

### GTA V (police)
1. **Essaie d'abord l'automatique** : écris un petit outil en C# basé sur la bibliothèque `CodeWalker.Core` (du dépôt CodeWalker), qui ouvre les `.rpf` en lecture seule, retrouve les fichiers par nom (`police3.yft`, `police3.ytd`, `s_m_y_cop_01.ydd`, `.yft`, `.ytd`, etc.) et les exporte au format XML Sollumz, avec les textures en DDS, dans `_extraction\gta\`. Il a besoin de la clé GTA lue depuis l'exe du jeu installé, comme le fait CodeWalker.
2. **Si ça bloque**, donne-moi la marche à suivre manuelle dans CodeWalker (RPF Explorer, chemins exacts, clic droit, « Export XML »). Je le fais, puis tu reprends.

### Garry's Mod (props)
- **Workshop** : extrais les `.gma` voulus avec `gmad.exe extract` (fourni dans `GarrysMod\bin\`) vers `_extraction\gmod\`.
- **Props de base** : SourceIO lit les `.vpk` directement. Pas besoin de les décompresser.

### FiveM (si j'en ai)
- Les dossiers `stream\` (`.yft`, `.ydr`, `.ytd`) suivent la même chaîne que GTA V.
- Les scripts (`client.lua`, `server.lua`, `fxmanifest.lua`) : lis-les et fais-en une **fiche de logique** dans `_extraction\fivem\NOTES.md` (événements, données, règles). On ne les exécute pas : ils servent de cahier des charges pour la phase 5.

## Phase 3 : conversion Blender → FBX (en lot, sans interface)

Écris `_extraction\convert.py` et lance-le avec `blender -b --python`. Pour chaque asset :
- import (Sollumz pour GTA, SourceIO pour Source) ;
- échelle et axes pour Unreal : 1 unité = 1 cm. Le modèle doit avoir la bonne taille et regarder vers l'avant (+X) ;
- **véhicules** : garde le châssis et les quatre roues comme os séparés et nomme-les clairement (`wheel_lf`, `wheel_rf`, `wheel_lr`, `wheel_rr`) pour Chaos Vehicles. Garde les gyrophares et les phares comme matériaux séparés ;
- **policiers** : un mesh avec son squelette, sans les LOD inutiles ;
- **props** : un Static Mesh par fichier, avec une collision simple (convexe) nommée `UCX_<nom>` ;
- textures en PNG ou TGA à côté du FBX ;
- export FBX dans `_extraction\fbx\<catégorie>\<nom>.fbx`.

Produis un rapport (nombre de fichiers, nombre de polygones, ceux qui ont échoué et pourquoi). Fais un rendu de contrôle en PNG de 3 assets de chaque catégorie pour vérifier que les textures sont bonnes.

## Phase 4 : import dans Unreal

Avec le MCP Unreal ou un script Python d'éditeur (`unreal.AssetImportTask`), importe dans `/Game/Imported/GTA/Vehicles`, `/Game/Imported/GTA/Peds` et `/Game/Imported/GMod/Props` :
- **matériaux** : un Material Master par type (opaque, verre, émissif pour les gyrophares) et des Material Instances par asset ;
- **véhicules** : Skeletal Mesh, Physics Asset, puis une Blueprint enfant de `ChaosWheeledVehiclePawn` par véhicule, avec les roues réglées. Ajoute les gyrophares (lumières qui alternent rouge et bleu) et une sirène activable ;
- **policiers** : Skeletal Mesh, puis un **IK Retargeter** vers le squelette Manny d'UE5, pour réutiliser les animations du projet ou du template ;
- **props** : Static Mesh avec simulation physique et masse cohérente.

Vérification : une map de test `/Game/Maps/Test_Imports` avec un exemplaire de chaque, une capture d'écran, et la conduite d'une voiture de police en PIE.

## Phase 5 : les systèmes de jeu

Construis dans cet ordre. Chaque système a sa map de test et doit être vérifié en PIE avant de passer au suivant :

1. **Bac à sable façon Garry's Mod**
   - **Menu de spawn** (UMG) : une grille générée automatiquement depuis `/Game/Imported/GMod/Props`, avec recherche. Un clic fait apparaître le prop devant le joueur.
   - **Physgun** (`PhysicsHandleComponent`) : attraper, rapprocher et éloigner à la molette, tourner (touche maintenue), figer et défiger, avec le faisceau visuel.
   - **Toolgun** avec des outils interchangeables : souder (`PhysicsConstraintComponent`), corde (Cable Component plus contrainte), supprimer, colorier.
   - **Undo** (touche Z) : une pile par joueur.
2. **Police façon GTA**
   - **Composant de recherche** (0 à 5 étoiles) : les crimes (tirer, frapper, voler un véhicule, renverser quelqu'un) font monter le niveau seulement s'ils sont vus. Il redescend après un délai hors de vue.
   - **Affichage** : les étoiles en HUD et le cercle de recherche sur la minimap.
   - **Dispatch** selon le niveau : patrouilles, puis voitures en poursuite, puis barrages, puis hélico.
   - **IA** (StateTree) : patrouille, poursuite à pied et en véhicule, tir, arrestation.
3. **Systèmes RP** (inspirés des notes FiveM si j'en ai fourni)
   - **Données** : inventaire (DataAssets pour les objets), argent liquide et banque, métiers (policier, mécanicien, taxi…).
   - **Interactions** : touche E, menu radial, garages.
   - **Sauvegarde** avec `SaveGame`, ou côté serveur en multijoueur.
   - En multijoueur : tout répliqué, avec la logique sur le serveur.

## Phase 6 : bilan

- Mets à jour `_extraction\JOURNAL.md` et écris `_extraction\README.md` : comment refaire l'extraction, les commandes, et ce qui reste à faire.
- Assure-toi que `_extraction\` et les fichiers extraits des jeux sont dans le `.gitignore` si le dépôt est poussé quelque part, même en privé.
- Fais le commit final et donne-moi un résumé court : ce qui marche (avec des captures), ce qui ne marche pas, et les prochaines étapes que tu proposes.

Commence par la phase 0.
