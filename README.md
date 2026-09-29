# MCP Unreal pour Claude Desktop

Installe [unreal-mcp](https://github.com/chongdashu/unreal-mcp) pour que Claude Desktop puisse piloter l'éditeur Unreal Engine (créer des acteurs, des Blueprints, etc.).

> **Unreal 5.8 ou plus récent ?** Tu n'as pas besoin de ce script : le moteur inclut un plugin MCP officiel (expérimental).
> Active-le dans Edit > Plugins (cherche « MCP »), redémarre l'éditeur, puis ajoute ceci dans `claude_desktop_config.json` (il faut [Node.js](https://nodejs.org)) :
>
> ```json
> { "mcpServers": { "unreal": { "command": "npx", "args": ["-y", "mcp-remote", "http://127.0.0.1:8000/mcp"] } } }
> ```

## Avant de commencer

- Windows 10/11
- Unreal Engine **5.5 ou plus récent**, avec un projet **C++** (par exemple le template Third Person en C++)
- Visual Studio 2022 avec le module « Développement de jeux en C++ »
- [Git](https://git-scm.com/download/win)
- Claude Desktop

## Installation

1. Télécharge ce dépôt (bouton **Code > Download ZIP**) et décompresse-le.
2. Ferme Unreal.
3. Double-clique sur **`installer-unreal-mcp.bat`** et colle le chemin du dossier de ton projet, par exemple `C:\Users\Toi\Documents\Unreal Projects\MonGTA`.

Le script :
- installe `uv` si besoin ;
- télécharge unreal-mcp dans `%USERPROFILE%\unreal-mcp` ;
- copie le plugin dans le dossier `Plugins\` de ton projet et l'active dans le `.uproject` ;
- ajoute le serveur `unrealMCP` dans `claude_desktop_config.json`.

Avant de modifier le `.uproject` et la config de Claude, il en fait une copie `.bak`.

## Ensuite, à la main

1. Clic droit sur ton `.uproject` > **Generate Visual Studio project files**.
2. Ouvre le `.sln`, choisis **Development Editor**, puis **Build**.
3. Ouvre ton projet dans Unreal.
4. Quitte complètement Claude Desktop (icône dans la barre des tâches > Quitter) et relance-le.
5. Avec Unreal ouvert, demande à Claude : *« Crée un cube au centre de la scène »*.

## En cas de problème

- **« Aucun fichier .uproject trouvé »** : donne le dossier qui *contient* le `.uproject`, pas le fichier lui-même.
- **Le plugin ne compile pas** : vérifie que le projet est bien en C++ (il faut un dossier `Source`) et que tu as la version 5.5 ou plus récente.
- **Claude ne voit pas l'outil** : dans Claude Desktop, va dans Paramètres > Développeur pour voir l'état du serveur `unrealMCP`.
- **Blocage PowerShell** : utilise le `.bat`, qui lance le script avec `-ExecutionPolicy Bypass`.
