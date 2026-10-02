# Plan : mon GTA-like sous UE 5.8, solo d'abord, prêt pour le multi (Seclin et le Nord + des systèmes piochés dans d'autres jeux)

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

Tu travailles sur mon jeu : un **GTA-like** sous Unreal Engine 5.8. Il est **solo pour l'instant**. Le multijoueur viendra plus tard : on ne le met pas en place maintenant, mais tout le code doit être écrit pour ne pas le bloquer. C'est un projet **perso et privé**, rien ne sera publié ni distribué. Le dossier courant est la racine du projet (là où se trouve le `.uproject`).

Je veux trois choses :
1. **Une fondation solo propre et « prête pour le multi ».** On ne met en place ni réseau, ni serveur, ni sessions, mais aucun choix d'architecture ne doit empêcher le multijoueur plus tard.
2. **Ma ville reproduite à partir de données publiques** (relief, routes, bâtiments, végétation). On commence par **Seclin** (Nord, 59, code INSEE 59560). Plus tard, on étendra aux communes voisines, puis au département du Nord.
3. **Un catalogue de systèmes modulaires.** Je dois pouvoir dire « je veux tel système de tel jeu » à tout moment, et l'avoir dans mon jeu sans casser le reste. Pour commencer : la police et la conduite de GTA V, le bac à sable de Garry's Mod, les systèmes RP de FiveM.

Utilise les skills du plugin universal-modder quand elles s'appliquent : `mod-any-game` et ses fiches moteur dans `references/engines/`, `game-recon`, `reverse-engineering`, `asset-pipeline`, `mashup-mods` (Pattern 1 : porter le contenu), `fal-assets`. Si le serveur MCP Unreal est connecté (plugin MCP intégré à UE 5.8), utilise-le pour agir dans l'éditeur. Sinon, utilise le Python de l'éditeur (`UnrealEditor-Cmd.exe <projet>.uproject -run=pythonscript -script=<fichier>.py`).

## Règles (valables pour toutes les phases)

- **Demande-moi avant** d'installer un logiciel, d'écrire dans un dossier de jeu, de lancer un jeu ou de télécharger plus de 5 Go.
- **Ne modifie jamais** les fichiers d'installation des autres jeux. Copie ce dont tu as besoin dans un dossier `_extraction\` à côté du projet. Ne lance aucun jeu en ligne et ne contourne aucun chiffrement (FiveM « escrow », DRM, anti-cheat).
- **Git** : vérifie que le projet est sous Git, avec Git LFS pour les `.uasset`/`.umap`. Sinon, propose de le mettre en place. Fais un commit à la fin de chaque étape validée. Les fichiers extraits des jeux et les données brutes de la carte restent hors du dépôt, via le `.gitignore`.
- **Solo d'abord, prêt pour le multi.** On développe et on teste **en solo** (PIE en mode Standalone). On ne met **pas** en place la réplication, les RPC, les sessions ou les serveurs, et on ne teste pas en multi. Mais le code suit ces habitudes, pour que le passage au multi soit un ajout et pas une réécriture :
  - la logique de jeu (règles, argent, dégâts, police, spawn d'objets) est dans le `GameMode`, le `GameState`, le `PlayerState` ou des composants de gameplay, jamais dans le HUD, les widgets ou le `PlayerController` ;
  - l'UI et les effets visuels ne font qu'**afficher** l'état, ils ne le modifient pas ;
  - les entrées du joueur passent par des **actions** (Gameplay Abilities, ou des fonctions du type « demander à faire X ») qui pourront devenir des requêtes au serveur ;
  - **jamais de « joueur 0 » en dur** : pas de `GetPlayerCharacter(0)` / `GetPlayerController(0)` dans le gameplay. On passe toujours par le joueur concerné ;
  - les données par joueur (argent, inventaire, niveau de recherche, permissions) sont rangées **par joueur** (`PlayerState` ou composant sur le joueur), même s'il n'y en a qu'un ;
  - les objets créés en jeu ont un **propriétaire** ;
  - préfère les solutions natives qui gèrent déjà le réseau (GAS, Chaos Vehicles, Character Movement, Gameplay Tags) aux solutions maison ;
  - quand un choix risque de poser problème en multi, note-le dans `Docs\MULTI.md` au lieu de le régler maintenant.
- **Preuves** : vérifie chaque résultat par une capture d'écran, un log ou un test automatisé, au lieu de supposer que ça a marché.
- **Journal** : tiens `Docs\JOURNAL.md` à jour (ce qui a été fait, versions des outils, problèmes rencontrés et leurs solutions).
- **Espace disque** : avant chaque phase, vérifie l'espace libre sur les disques (`Get-PSDrive -PSProvider FileSystem`) et compare-le au budget de la section « Espace disque » ci-dessous. S'il manque de la place, arrête-toi et propose où mettre les données (un autre disque, le dossier du cache DDC ailleurs). Ne télécharge jamais un jeu de données entier (département ou région) quand l'emprise de Seclin suffit.
- Si une étape échoue deux fois de la même manière, arrête-toi et explique-moi le problème au lieu d'insister.
- Parle-moi en français.

## Espace disque (estimations)

Ordres de grandeur, à vérifier en phase 0. « Si absent » veut dire : seulement si le logiciel n'est pas déjà installé. Prévois un **SSD NVMe** pour le projet et le cache (DDC).

| Étape | Contenu | Estimation |
|---|---|---|
| Outils de base (si absents) | Unreal Engine 5.8 par le launcher (sans symboles de débogage) | 60 à 80 Go |
| | Visual Studio 2022, module « Développement de jeux en C++ » | 25 à 40 Go |
| | Blender + addons, QGIS, .NET SDK, Python, Git LFS | 4 à 6 Go |
| Phase 1 : architecture | Projet C++ compilé (`Binaries`, `Intermediate`), cache DDC de départ | 15 à 30 Go |
| Phase 2 : Seclin (données brutes) | LiDAR HD MNT (≈ 25 à 30 dalles de 1 km²) | 0,5 à 1 Go |
| | BD ORTHO 20 cm limitée à l'emprise | 1 à 3 Go |
| | BD TOPO (archive du département si pas d'extraction par emprise) | 1 à 3 Go |
| | OpenStreetMap (Overpass sur l'emprise) | moins de 0,2 Go |
| | Nuages de points LiDAR (`.laz`), **optionnel**, pour des bâtiments plus fidèles | 4 à 10 Go |
| Phase 2 : Seclin (dans Unreal) | Landscape, routes, bâtiments PCG, végétation, textures | 10 à 25 Go |
| Phase 3 : assets d'autres jeux | GTA V et Garry's Mod **non comptés** (≈ 110 Go et ≈ 5 à 10 Go s'ils ne sont pas installés) | — |
| | Extraction (`_extraction\`) + fichiers Blender + FBX | 5 à 15 Go |
| | Assets importés dans Unreal | 3 à 8 Go |
| Phases 4 et 5 : systèmes | Code, Blueprints, maps de test, croissance du cache DDC | 5 à 15 Go |
| | Une version empaquetée du jeu pour tester (optionnel) | 5 à 15 Go |
| Git | Historique local avec Git LFS (grossit à chaque commit d'assets) | 10 à 30 Go |

**Totaux pour Seclin :**
- **Moteur et Visual Studio déjà installés** : prévoir **≈ 60 à 130 Go** libres. 150 Go sont confortables.
- **Tout à installer** (moteur, Visual Studio, outils) : prévoir **≈ 150 à 260 Go** libres. 300 Go sont confortables.

**Pour plus tard (à titre indicatif) :**
- chaque commune voisine de taille comparable ajoute environ **10 à 30 Go** (données et contenu Unreal) ;
- le **département du Nord entier** (≈ 5 700 km²) au même niveau de détail dépasserait **plusieurs To**. Il faudra alors un niveau de détail réduit hors des villes jouables (relief à 5 m, bâtiments simplifiés), ou Cesium pour le lointain ;
- un moteur **compilé depuis les sources** (utile le jour où on passera au serveur dédié) demande **200 à 300 Go** de plus.

**Matériel conseillé** : 32 Go de RAM au minimum (64 Go confortables pour la génération de la carte), carte graphique de 8 Go de VRAM ou plus.

## Phase 0 : questions et inventaire (ne rien installer)

1. Pose-moi ces questions en une seule fois :
   - **Zone pilote dans Seclin** : propose le centre-ville (autour de la mairie et de la collégiale Saint-Piat) sur 1 à 2 km², avant d'étendre à toute la commune. Montre-moi l'emprise proposée sur une capture de carte ;
   - **C++ ou Blueprint ?** Recommande du C++ pour le cœur et les systèmes, avec des Blueprints enfants pour le réglage ;
   - quels jeux j'ai installés et où, pour piocher dedans (GTA V, Garry's Mod, ressources FiveM, autres).
2. Trouve tout seul et liste :
   - le `.uproject`, la version exacte du moteur, s'il est compilé depuis les sources ou installé par le launcher, la présence de `Source\`, les plugins actifs ;
   - les jeux installés (`um scan`, registre Steam/Epic/Rockstar, `libraryfolders.vdf`) ;
   - les outils présents : Visual Studio, .NET SDK, Python, Git et Git LFS, Blender (version et addons), QGIS, CodeWalker ;
   - l'espace libre de chaque disque, la RAM, la carte graphique et sa VRAM. Compare avec la section « Espace disque » et recommande sur quel disque mettre quoi.
3. Écris `Docs\PLAN.md`, avec l'architecture proposée, l'ordre des étapes et la liste de ce qu'il faut installer. Puis **attends mon feu vert**.

## Phase 1 : architecture modulaire (solo, prête pour le multi)

L'objectif : chaque système venu d'un autre jeu doit être une **brique indépendante**, qu'on peut ajouter, activer ou retirer.

1. **Structure du code**
   - un module C++ `Core` (le jeu de base : `GameMode`, `GameState`, `PlayerState`, `PlayerController`, `Character`) ;
   - un **plugin Game Feature par système**, dans `Plugins\GameFeatures\<NomDuSysteme>\` (par exemple `WantedLevel`, `SandboxTools`, `RPJobs`). Chaque plugin s'active et se désactive tout seul ;
   - les briques communes dans le Core : **Gameplay Ability System (GAS)** pour les actions, armes et effets (il gérera aussi le réseau plus tard), **Gameplay Tags**, **Enhanced Input**, un composant d'**interaction** (touche E) et un **inventaire** de base rangé par joueur.
2. **Préparation du multi (sans le mettre en place)**
   - applique les règles « solo d'abord, prêt pour le multi » ci-dessus dans tout le Core ;
   - **World Partition** pour la carte (indispensable pour une grande carte, solo comme multi) ;
   - crée `Docs\MULTI.md` : les règles suivies, et la liste des points à traiter le jour où on passera au multi.
3. **Tests**
   - une map `/Game/Maps/Test_Core`, testée en solo ;
   - un test automatisé (Automation ou Functional Test) qui vérifie les déplacements, l'entrée dans un véhicule et une capacité GAS.
4. **Mémoire du projet pour les prochaines sessions**
   - crée ou complète un `CLAUDE.md` à la racine : architecture, conventions (noms, dossiers, règles « prêt pour le multi »), comment compiler, tester et lancer ;
   - crée la commande **`/ajouter-systeme`** dans `.claude\skills\ajouter-systeme\SKILL.md`. Elle reprend exactement la **recette** de la phase 4 ci-dessous, pour que je puisse ajouter n'importe quel système dans une nouvelle session ;
   - crée `Docs\SYSTEMES.md` : le catalogue des systèmes ajoutés (jeu d'origine, plugin, état, comment le tester).

## Phase 2 : Seclin à partir de données publiques

Les données de l'IGN sont libres (Licence Ouverte Etalab), et OpenStreetMap est sous licence ODbL. **Commence par la zone pilote, puis toute la commune de Seclin.**

0. **Emprise**
   - récupère le contour officiel de la commune : `https://geo.api.gouv.fr/communes?code=59560&format=geojson&geometry=contour` ;
   - calcule l'emprise en Lambert-93 (EPSG:2154) avec une **marge de 500 m** autour du contour (pour l'horizon et les routes qui sortent de la ville). Enregistre-la dans `Tools\Map\zones\seclin.geojson` ;
   - **ne télécharge que ce qui couvre cette emprise** : des dalles (LiDAR HD, ortho) ou des requêtes par emprise (Géoplateforme WFS/WMTS, Overpass), pas les archives du département entier, sauf la BD TOPO si elle n'existe qu'au département (environ 1 à 2 Go, à me demander) ;
   - repères à vérifier sur place : le centre-ville et la collégiale Saint-Piat, l'autoroute A1, les zones d'activités, la voie ferrée et la gare, et l'aéroport de Lille-Lesquin juste à côté (en limite de carte) ;
   - le relief du secteur est très plat : vérifie que le Landscape reste net malgré de faibles écarts d'altitude (échelle Z adaptée).

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
5. Écris le pipeline dans des scripts relançables (`Tools\Map\*.py`). Je dois pouvoir **étendre la carte à une nouvelle commune** avec une seule commande (par exemple `python Tools\Map\build.py --commune 59343` pour Lesquin), en ajoutant une zone à côté des précédentes.
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
   - écris une **fiche** `Docs\Systemes\<Nom>.md` : ce que voit le joueur, les règles, les données, et ce qui sera partagé entre joueurs le jour où on passera au multi ;
   - montre-moi la fiche et attends mon accord, surtout s'il y a des choix à faire.
2. **Concevoir.**
   - un nouveau plugin Game Feature ;
   - les briques du Core qu'il réutilise (GAS, interaction, inventaire) ;
   - où vit l'état (`GameState`, `PlayerState`, composant) et ce qui devra être synchronisé plus tard en multi (à noter dans `Docs\MULTI.md`, sans l'implémenter) ;
   - ses points de branchement avec les autres systèmes (par exemple : un crime remonte au système de police par un événement taggé, pas par un appel direct).
3. **Construire** une première version qui marche, puis l'enrichir. Avec les assets via la phase 3 si besoin.
4. **Vérifier** en solo avec une map de test dédiée, des captures et un test automatisé. Relis le code avec les règles « prêt pour le multi ».
5. **Enregistrer** : ligne dans `Docs\SYSTEMES.md`, journal, commit.

## Phase 5 : premiers systèmes (avec la recette de la phase 4, dans cet ordre)

1. **Véhicules façon GTA** : Chaos Vehicles (entrer et sortir, places passager, dégâts, klaxon, radio), avec un véhicule importé de GTA V comme test.
2. **Police façon GTA V** :
   - niveau de recherche (0 à 5 étoiles) **rangé par joueur**, qui monte seulement sur des crimes vus et redescend hors de vue ;
   - affichage : HUD et cercle de recherche sur la minimap ;
   - dispatch qui utilise le graphe routier de la phase 2 ;
   - IA avec StateTree, véhicules de police importés et gyrophares.
3. **Bac à sable façon Garry's Mod** :
   - menu de spawn ;
   - physgun ;
   - toolgun (souder, corde, supprimer, colorier) ;
   - undo par joueur ;
   - chaque objet posé a un **propriétaire** (ça servira aux permissions en multi).
4. **RP façon FiveM** :
   - inventaire, argent liquide et banque, métiers (policier joueur, mécanicien, taxi…), menu radial, garages ;
   - sauvegarde avec `SaveGame`, organisée par joueur pour pouvoir passer côté serveur plus tard ;
   - si j'ai des ressources FiveM en clair, lis leurs scripts pour en tirer le cahier des charges. On ne les exécute pas.

## Phase 6 : bilan

- Mets à jour `CLAUDE.md`, `Docs\SYSTEMES.md`, `Docs\MULTI.md` et `Docs\JOURNAL.md`.
- Fais le commit final et donne-moi un résumé court : ce qui marche (avec des captures), ce qui ne marche pas, et les prochaines étapes que tu proposes.

Commence par la phase 0.
