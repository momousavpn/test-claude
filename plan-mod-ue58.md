# Plan : mon GTA-like multijoueur sous UE 5.8 (mon département + des systèmes piochés dans d'autres jeux)

> **Comment l'utiliser**
> 1. Ouvre PowerShell **dans le dossier de ton projet Unreal** (celui qui contient le `.uproject`), puis lance `claude`.
> 2. Tape d'abord ces deux commandes (une par une) pour installer les skills universal-modder :
>    ```
>    /plugin marketplace add rehan-remade/universal-modder
>    /plugin install universal-modder@universal-modder
>    ```
> 3. Colle **tout le texte sous la ligne** ci-dessous dans Claude et appuie sur Entrée.
>
> Claude pose d'abord ses questions, puis avance phase par phase. Il demande ton accord avant d'installer un logiciel ou de toucher à un dossier de jeu.
>
> **Ensuite, pour ajouter n'importe quel système :** dans une nouvelle session, tape simplement
> `/ajouter-systeme le système de recherche de la police de GTA V` ou
> `/ajouter-systeme le physgun de Garry's Mod` ou
> `/ajouter-systeme la construction de base de Rust`.
> Cette commande est créée par Claude pendant la phase 1.

---

Tu travailles sur mon jeu : un **GTA-like multijoueur** sous Unreal Engine 5.8. C'est un projet **perso et privé**, rien ne sera publié ni distribué. Le dossier courant est la racine du projet (là où se trouve le `.uproject`).

Je veux trois choses :
1. **Une fondation multijoueur solide.** Tout le jeu est pensé pour le multijoueur dès le départ.
2. **Mon département français reproduit** à partir de données publiques (relief, routes, bâtiments, végétation).
3. **Un catalogue de systèmes modulaires.** Je dois pouvoir dire « je veux tel système de tel jeu » à tout moment, et l'avoir dans mon jeu sans casser le reste. Pour commencer : la police et la conduite de GTA V, le bac à sable de Garry's Mod, les systèmes RP de FiveM.

Utilise les skills du plugin universal-modder quand elles s'appliquent : `mod-any-game` et ses fiches moteur dans `references/engines/`, `game-recon`, `reverse-engineering`, `asset-pipeline`, `mashup-mods` (Pattern 1 : porter le contenu), `fal-assets`. Si le serveur MCP Unreal est connecté (plugin MCP intégré à UE 5.8), utilise-le pour agir dans l'éditeur. Sinon, utilise le Python de l'éditeur (`UnrealEditor-Cmd.exe <projet>.uproject -run=pythonscript -script=<fichier>.py`).

## Règles (valables pour toutes les phases)

- **Demande-moi avant** d'installer un logiciel, d'écrire dans un dossier de jeu, de lancer un jeu ou de télécharger plus de 5 Go.
- **Ne modifie jamais** les fichiers d'installation des autres jeux. Copie ce dont tu as besoin dans un dossier `_extraction\` à côté du projet. Ne lance aucun jeu en ligne et ne contourne aucun chiffrement (FiveM « escrow », DRM, anti-cheat).
- **Git** : vérifie que le projet est sous Git, avec Git LFS pour les `.uasset`/`.umap`. Sinon, propose de le mettre en place. Fais un commit à la fin de chaque étape validée. Les fichiers extraits des jeux et les données brutes de la carte restent hors du dépôt, via le `.gitignore`.
- **Multijoueur d'abord** : tout gameplay est **décidé côté serveur** et répliqué. Rien ne doit dépendre d'un seul joueur local. Chaque fonctionnalité est testée en PIE avec **au moins 2 clients** en mode « Play as Client », pas seulement en solo.
- **Preuves** : vérifie chaque résultat par une capture d'écran, un log ou un test automatisé, au lieu de supposer que ça a marché.
- **Journal** : tiens `Docs\JOURNAL.md` à jour (ce qui a été fait, versions des outils, problèmes rencontrés et leurs solutions).
- Si une étape échoue deux fois de la même manière, arrête-toi et explique-moi le problème au lieu d'insister.
- Parle-moi en français.

## Phase 0 : questions et inventaire (ne rien installer)

1. Pose-moi ces questions en une seule fois :
   - **Quel département ?** Et par quelle zone commencer : propose une **zone pilote** de 2 à 4 km² (un centre-ville avec une route principale), pas le département entier d'un coup ;
   - **Serveur dédié ou listen server ?** Un serveur dédié demande un moteur **compilé depuis les sources** (GitHub Epic). Propose de commencer en listen server tout en codant comme pour un serveur dédié, puis de passer au dédié plus tard ;
   - **Nombre de joueurs visé** par serveur (8 ? 32 ? 64+ ?). Ça change les choix de réplication ;
   - **C++ ou Blueprint ?** Recommande du C++ pour le cœur et les systèmes, avec des Blueprints enfants pour le réglage ;
   - quels jeux j'ai installés et où, pour piocher dedans (GTA V, Garry's Mod, ressources FiveM, autres).
2. Trouve tout seul et liste :
   - le `.uproject`, la version exacte du moteur, s'il est compilé depuis les sources ou installé par le launcher, la présence de `Source\`, les plugins actifs ;
   - les jeux installés (`um scan`, registre Steam/Epic/Rockstar, `libraryfolders.vdf`) ;
   - les outils présents : Visual Studio, .NET SDK, Python, Git et Git LFS, Blender (version et addons), QGIS, CodeWalker.
3. Écris `Docs\PLAN.md`, avec l'architecture proposée, l'ordre des étapes et la liste de ce qu'il faut installer. Puis **attends mon feu vert**.

## Phase 1 : architecture modulaire et fondation multijoueur

L'objectif : chaque système venu d'un autre jeu doit être une **brique indépendante**, qu'on peut ajouter, activer ou retirer.

1. **Structure du code**
   - un module C++ `Core` (le jeu de base : `GameMode`, `GameState`, `PlayerState`, `PlayerController`, `Character`) ;
   - un **plugin Game Feature par système**, dans `Plugins\GameFeatures\<NomDuSysteme>\` (par exemple `WantedLevel`, `SandboxTools`, `RPJobs`). Chaque plugin s'active et se désactive tout seul ;
   - les briques communes dans le Core : **Gameplay Ability System (GAS)** pour les actions, armes et effets répliqués, **Gameplay Tags**, **Enhanced Input**, un composant d'**interaction** (touche E) et un **inventaire répliqué** de base.
2. **Fondation réseau**
   - gameplay décidé côté serveur, appels RPC limités et validés ;
   - réplication avec **Iris** si elle est stable dans 5.8 (vérifie dans la doc et dans les plugins de ton moteur), sinon la réplication classique avec `ReplicationGraph` ou les réglages de pertinence ;
   - **World Partition** avec le streaming réseau des cellules ;
   - sessions : d'abord en local (LAN ou commande `open`), puis **Epic Online Services** si je le demande.
3. **Tests**
   - une map `/Game/Maps/Test_Multi`, 2 à 4 clients en PIE ;
   - un test automatisé (Automation ou Functional Test) qui vérifie que les déplacements, l'entrée dans un véhicule et une capacité GAS sont bien répliqués.
4. **Mémoire du projet pour les prochaines sessions**
   - crée ou complète un `CLAUDE.md` à la racine : architecture, conventions (noms, dossiers, règles réseau), comment compiler, tester et lancer en multi ;
   - crée la commande **`/ajouter-systeme`** dans `.claude\skills\ajouter-systeme\SKILL.md`. Elle reprend exactement la **recette** de la phase 4 ci-dessous, pour que je puisse ajouter n'importe quel système dans une nouvelle session ;
   - crée `Docs\SYSTEMES.md` : le catalogue des systèmes ajoutés (jeu d'origine, plugin, état, comment le tester).

## Phase 2 : mon département à partir de données publiques

Les données de l'IGN sont libres (Licence Ouverte Etalab), et OpenStreetMap est sous licence ODbL. **Commence par la zone pilote.**

1. **Relief**
   - **RGE ALTI 1 m** ou **LiDAR HD** (MNT) de l'IGN, sur la Géoplateforme (cartes.gouv.fr / geoservices.ign.fr) ;
   - avec **QGIS** ou GDAL : découpe, reprojection (Lambert-93), puis export en **heightmap PNG 16 bits** aux tailles qu'accepte le Landscape d'Unreal ;
   - import en **Landscape** avec World Partition. Note l'échelle Z exacte dans le journal.
2. **Routes, bâtiments, eau, végétation**
   - **BD TOPO** de l'IGN (bâtiments avec leur hauteur, routes avec leur largeur et leur importance, cours d'eau, zones de végétation), complétée par **OpenStreetMap** (noms de rues, type de commerce, nombre d'étages) via Overpass ou Geofabrik ;
   - routes : des splines (Landscape Splines ou PCG), avec les intersections et un **graphe routier** réutilisable par l'IA de conduite et la police ;
   - bâtiments : génération **PCG** à partir de l'emprise et de la hauteur. D'abord des volumes simples et propres, avec des styles par type (habitation, commerce, industriel) ;
   - végétation, eau et mobilier urbain : PCG, à partir des zones BD TOPO et OSM.
3. **Références visuelles** : la **BD ORTHO** (photos aériennes) de l'IGN, comme calque de référence et pour colorer le sol au loin.
4. **Optionnel** : le plugin **Cesium for Unreal** (gratuit), pour l'horizon lointain ou la vérification du géoréférencement.
5. Écris le pipeline dans des scripts relançables (`Tools\Map\*.py`). Je dois pouvoir **étendre la carte à une nouvelle zone** du département avec une seule commande.
6. **Vérification** : des captures vues du ciel comparées à l'orthophoto, et le trajet d'une voiture sur une vraie rue d'un bout à l'autre.

## Phase 3 : pipeline d'assets venus d'autres jeux

Chaîne générale : extraction (lecture seule) dans `_extraction\<jeu>\`, puis conversion Blender en lot, puis FBX, puis import dans Unreal.

- **Outils par moteur** (installés seulement quand un système en a besoin, et après mon accord) :
  - GTA V / FiveM (`.yft`, `.ydr`, `.ydd`, `.ytd`) : **CodeWalker** (ou un outil C# basé sur `CodeWalker.Core` pour automatiser), puis **Sollumz** dans Blender ;
  - Source / Garry's Mod (`.mdl`, `.vtf`, `.vpk`, `.gma`) : `gmad.exe extract`, puis **SourceIO** dans Blender ;
  - Unreal : **FModel** ; Unity : **AssetRipper** ;
  - autres moteurs : voir la skill `reverse-engineering` et la fiche du moteur concerné.
- Lis les opérateurs réellement exposés par les addons installés (`dir(bpy.ops.<addon>)`) au lieu de deviner leurs noms.
- **Conversion** (`Tools\Assets\convert.py`, lancé avec `blender -b`) :
  - échelle en cm, avant du modèle sur +X ;
  - véhicules : roues comme os séparés (`wheel_lf`, `wheel_rf`, `wheel_lr`, `wheel_rr`), matériaux émissifs séparés pour les feux ;
  - personnages : squelette conservé, puis **IK Retargeter** vers Manny dans UE ;
  - props : collision convexe nommée `UCX_<nom>`.
- **Import** (`Tools\Assets\import.py`) dans `/Game/Imported/<Jeu>/<Catégorie>/`, avec des Material Instances basées sur des matériaux maîtres communs.
- Faute d'asset extractible, propose une alternative : génération avec fal (`fal-assets`) ou asset libre sur Fab.

## Phase 4 : recette pour ajouter un système de n'importe quel jeu

C'est la recette que `/ajouter-systeme` doit suivre. Quand je dis « je veux le système X du jeu Y » :

1. **Comprendre.** Recherche comment le système fonctionne dans le jeu Y :
   - ses règles, ses chiffres (vitesses, délais, dégâts) et ses cas particuliers ;
   - les sources : wiki, documentation de mods, et si besoin les données ou le code du jeu (skill `reverse-engineering`), si le jeu est installé ;
   - écris une **fiche** `Docs\Systemes\<Nom>.md` : ce que voit le joueur, les règles, les données, et ce qui est répliqué (serveur ou client) ;
   - montre-moi la fiche et attends mon accord, surtout s'il y a des choix à faire.
2. **Concevoir.**
   - un nouveau plugin Game Feature ;
   - les briques du Core qu'il réutilise (GAS, interaction, inventaire) ;
   - son modèle réseau (ce que fait le serveur, ce qui est répliqué, les RPC) ;
   - ses points de branchement avec les autres systèmes (par exemple : un crime remonte au système de police par un événement taggé, pas par un appel direct).
3. **Construire** une première version qui marche, puis l'enrichir. Avec les assets via la phase 3 si besoin.
4. **Vérifier** en multijoueur (2 clients ou plus) avec une map de test dédiée, des captures et un test automatisé.
5. **Enregistrer** : ligne dans `Docs\SYSTEMES.md`, journal, commit.

## Phase 5 : premiers systèmes (avec la recette de la phase 4, dans cet ordre)

1. **Véhicules façon GTA** : Chaos Vehicles répliqués (entrer et sortir, places passager, dégâts, klaxon, radio), avec un véhicule importé de GTA V comme test.
2. **Police façon GTA V** :
   - niveau de recherche (0 à 5 étoiles) **par joueur**, géré par le serveur, qui monte seulement sur des crimes vus et redescend hors de vue ;
   - affichage : HUD et cercle de recherche sur la minimap ;
   - dispatch qui utilise le graphe routier de la phase 2 ;
   - IA avec StateTree, véhicules de police importés et gyrophares.
3. **Bac à sable façon Garry's Mod** :
   - menu de spawn ;
   - physgun (physique gérée par le serveur, avec prédiction et lissage côté client) ;
   - toolgun (souder, corde, supprimer, colorier) ;
   - undo par joueur ;
   - **permissions** (qui peut toucher les objets de qui), indispensables en multijoueur.
4. **RP façon FiveM** :
   - inventaire, argent liquide et banque, métiers (policier joueur, mécanicien, taxi…), menu radial, garages ;
   - sauvegarde côté serveur ;
   - si j'ai des ressources FiveM en clair, lis leurs scripts pour en tirer le cahier des charges. On ne les exécute pas.

## Phase 6 : bilan

- Mets à jour `CLAUDE.md`, `Docs\SYSTEMES.md` et `Docs\JOURNAL.md`.
- Fais le commit final et donne-moi un résumé court : ce qui marche (avec des captures), ce qui ne marche pas, et les prochaines étapes que tu proposes.

Commence par la phase 0.
