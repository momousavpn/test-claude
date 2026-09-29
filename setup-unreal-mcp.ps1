<#
  Installe le MCP Unreal (github.com/chongdashu/unreal-mcp) et le branche sur Claude Desktop.

  Ce que fait le script :
    1. Verifie Git et installe uv (gestionnaire Python) si besoin
    2. Telecharge unreal-mcp (ou le met a jour)
    3. Copie le plugin UnrealMCP dans ton projet Unreal et l'active dans le .uproject
    4. Ajoute le serveur "unrealMCP" dans la config de Claude Desktop (avec sauvegarde)

  Utilisation (PowerShell) :
    .\setup-unreal-mcp.ps1 -ProjectPath "C:\Users\Toi\Documents\Unreal Projects\MonGTA"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectPath,

    [string]$InstallDir = (Join-Path $env:USERPROFILE "unreal-mcp")
)

$ErrorActionPreference = "Stop"

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    OK : $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    ATTENTION : $msg" -ForegroundColor Yellow }

# Ecrit du JSON en UTF-8 sans BOM (un BOM peut casser la lecture par Claude Desktop)
function Write-JsonFile($path, $obj) {
    $json = $obj | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

# Ajoute ou remplace une propriete sur un objet issu de ConvertFrom-Json
function Set-Prop($obj, $name, $value) {
    if ($obj.PSObject.Properties[$name]) { $obj.$name = $value }
    else { $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
}

# --- 0. Verifications ---------------------------------------------------------
Step "Verification du projet Unreal"
$uproject = Get-ChildItem -Path $ProjectPath -Filter *.uproject -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $uproject) {
    throw "Aucun fichier .uproject trouve dans '$ProjectPath'. Donne le dossier qui contient ton .uproject."
}
if (-not (Test-Path (Join-Path $ProjectPath "Source"))) {
    Warn "Pas de dossier Source : ton projet semble etre 100% Blueprint. Le plugin est en C++,"
    Warn "ajoute une classe C++ (Tools > New C++ Class) pour que le projet puisse le compiler."
}
Ok $uproject.FullName

Step "Verification de Git"
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git n'est pas installe. Installe-le depuis https://git-scm.com/download/win puis relance le script."
}
Ok (git --version)

# --- 1. uv --------------------------------------------------------------------
Step "Installation de uv"
$uvExe = Join-Path $env:USERPROFILE ".local\bin\uv.exe"
$uvCmd = Get-Command uv -ErrorAction SilentlyContinue
if ($uvCmd) {
    $uvExe = $uvCmd.Source
    Ok "uv deja installe ($uvExe)"
} elseif (Test-Path $uvExe) {
    Ok "uv deja installe ($uvExe)"
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    if (-not (Test-Path $uvExe)) { throw "uv n'a pas ete trouve apres installation ($uvExe)." }
    Ok "uv installe ($uvExe)"
}

# --- 2. unreal-mcp ------------------------------------------------------------
Step "Telechargement de unreal-mcp dans $InstallDir"
if (Test-Path (Join-Path $InstallDir ".git")) {
    git -C $InstallDir pull --ff-only
    Ok "mis a jour"
} else {
    git clone https://github.com/chongdashu/unreal-mcp.git $InstallDir
    Ok "clone"
}
$pythonDir = Join-Path $InstallDir "Python"

Step "Installation des dependances Python (uv telecharge Python si besoin)"
& $uvExe --directory $pythonDir sync
Ok "dependances pretes"

# --- 3. Plugin dans le projet -------------------------------------------------
Step "Copie du plugin UnrealMCP dans le projet"
$pluginSrc = Join-Path $InstallDir "MCPGameProject\Plugins\UnrealMCP"
$pluginsDir = Join-Path $ProjectPath "Plugins"
$pluginDst = Join-Path $pluginsDir "UnrealMCP"
New-Item -ItemType Directory -Force -Path $pluginsDir | Out-Null
if (Test-Path $pluginDst) { Remove-Item -Recurse -Force $pluginDst }
Copy-Item -Recurse $pluginSrc $pluginDst
Ok $pluginDst

Step "Activation du plugin dans $($uproject.Name)"
Copy-Item $uproject.FullName "$($uproject.FullName).bak" -Force
$proj = Get-Content $uproject.FullName -Raw | ConvertFrom-Json
$plugins = @()
if ($proj.PSObject.Properties["Plugins"]) { $plugins = @($proj.Plugins) }
$plugins = @($plugins | Where-Object { $_.Name -ne "UnrealMCP" })
$plugins += [pscustomobject]@{ Name = "UnrealMCP"; Enabled = $true }
Set-Prop $proj "Plugins" $plugins
Write-JsonFile $uproject.FullName $proj
Ok "active (sauvegarde : $($uproject.Name).bak)"

# --- 4. Config Claude Desktop -------------------------------------------------
Step "Configuration de Claude Desktop"
# Version classique, puis version Microsoft Store
$candidates = @(Join-Path $env:APPDATA "Claude")
$storePkg = Get-ChildItem (Join-Path $env:LOCALAPPDATA "Packages") -Directory -Filter "Claude_*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($storePkg) { $candidates += Join-Path $storePkg.FullName "LocalCache\Roaming\Claude" }
$configDir = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $configDir) { $configDir = $candidates[0]; New-Item -ItemType Directory -Force -Path $configDir | Out-Null }
$configPath = Join-Path $configDir "claude_desktop_config.json"

$config = [pscustomobject]@{}
if (Test-Path $configPath) {
    Copy-Item $configPath "$configPath.bak" -Force
    $raw = Get-Content $configPath -Raw
    if ($raw -and $raw.Trim()) { $config = $raw | ConvertFrom-Json }
}
if (-not $config.PSObject.Properties["mcpServers"]) { Set-Prop $config "mcpServers" ([pscustomobject]@{}) }
Set-Prop $config.mcpServers "unrealMCP" ([pscustomobject]@{
    command = $uvExe
    args    = @("--directory", $pythonDir, "run", "unreal_mcp_server.py")
})
Write-JsonFile $configPath $config
Ok $configPath

# --- Fin ----------------------------------------------------------------------
Write-Host "`nInstallation terminee !" -ForegroundColor Green
Write-Host @"

Il te reste a faire (a la main) :
  1. Clic droit sur $($uproject.Name) > "Generate Visual Studio project files"
  2. Ouvre le .sln dans Visual Studio, cible "Development Editor", puis Build
  3. Ouvre le projet dans Unreal (le plugin UnrealMCP doit etre actif dans Edit > Plugins)
  4. Quitte completement Claude Desktop (icone de la barre des taches > Quitter) et relance-le
  5. Dans Claude Desktop, avec Unreal ouvert, demande : "Cree un cube au centre de la scene"
"@
