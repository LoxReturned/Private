function Get-GameList {
    return @(
        @{ Name = 'Valorant'; Paths = @('C:\Riot Games\VALORANT') },
        @{ Name = 'CS 1.6'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\Half-Life') },
        @{ Name = 'CS:GO'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\Counter-Strike Global Offensive') },
        @{ Name = 'League of Legends'; Paths = @('C:\Riot Games\League of Legends') },
        @{ Name = 'Dota 2'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta') },
        @{ Name = 'Fortnite'; Paths = @('C:\Program Files\Epic Games\Fortnite') },
        @{ Name = 'Minecraft'; Paths = @("$env:APPDATA\.minecraft") },
        @{ Name = 'Roblox'; Paths = @("$env:LOCALAPPDATA\Roblox") },
        @{ Name = 'Rocket League'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\rocketleague') },
        @{ Name = 'Team Fortress 2'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\Team Fortress 2') },
        @{ Name = 'Stardew Valley'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\Stardew Valley') },
        @{ Name = 'Among Us'; Paths = @('C:\Program Files (x86)\Steam\steamapps\common\Among Us') },
        @{ Name = 'Trackmania'; Paths = @('C:\Program Files\Ubisoft\Trackmania') },
        @{ Name = 'Overwatch 2'; Paths = @('C:\Program Files (x86)\Overwatch') },
        @{ Name = 'Crossfire'; Paths = @('C:\Program Files (x86)\Crossfire') }
    )
}

function Test-GameInstalled {
    param([hashtable]$Game)
    foreach ($path in $Game.Paths) { if (Test-Path $path) { return $true } }
    return $false
}

function Optimize-Game {
    param([hashtable]$Game, [hashtable]$Options = @{})
    if (Test-WhatIf $Options "Optimize $($Game.Name)") { return }
    switch ($Game.Name) {
        'Valorant' { Optimize-Valorant }
        'CS 1.6' { Optimize-CSLegacy }
        'CS:GO' { Optimize-CSGO }
        'League of Legends' { Optimize-LoL }
        'Dota 2' { Optimize-Dota2 }
        'Fortnite' { Optimize-Fortnite }
        'Minecraft' { Optimize-Minecraft }
        'Roblox' { Optimize-Roblox }
        'Rocket League' { Optimize-RocketLeague }
        'Team Fortress 2' { Optimize-TF2 }
        'Stardew Valley' { Optimize-Stardew }
        'Among Us' { Optimize-AmongUs }
        'Trackmania' { Optimize-Trackmania }
        'Overwatch 2' { Optimize-Overwatch }
        'Crossfire' { Optimize-Crossfire }
    }
}

function Reset-Game {
    param([hashtable]$Game, [hashtable]$Options = @{})
    if (Test-WhatIf $Options "Reset $($Game.Name)") { return }
    switch ($Game.Name) {
        'Valorant' { Reset-Valorant }
        'CS 1.6' { Reset-CSLegacy }
        'CS:GO' { Reset-CSGO }
        'League of Legends' { Reset-LoL }
        'Dota 2' { Reset-Dota2 }
        'Fortnite' { Reset-Fortnite }
        'Minecraft' { Reset-Minecraft }
        'Roblox' { Reset-Roblox }
        'Rocket League' { Reset-RocketLeague }
        'Team Fortress 2' { Reset-TF2 }
        'Stardew Valley' { Reset-Stardew }
        'Among Us' { Reset-AmongUs }
        'Trackmania' { Reset-Trackmania }
        'Overwatch 2' { Reset-Overwatch }
        'Crossfire' { Reset-Crossfire }
    }
}

function Set-IniValue {
    param([string]$Path, [string]$Key, [string]$Value)
    if (-not (Test-Path $Path)) { return }
    $content = Get-Content $Path
    if ($content -match "^$Key=") {
        $content = $content -replace "^$Key=.*", "$Key=$Value"
    } else {
        $content += "$Key=$Value"
    }
    $content | Set-Content -Path $Path
}

function Optimize-Valorant {
    $config = "${env:LOCALAPPDATA}\VALORANT\Saved\Config\Windows\GameUserSettings.ini"
    Set-IniValue -Path $config -Key 'bUseVSync' -Value 'False'
    Set-IniValue -Path $config -Key 'bShouldRunInFullscreen' -Value 'True'
    Set-IniValue -Path $config -Key 'FullscreenMode' -Value '0'
    Write-Log -Message 'Valorant optimized.'
}
function Reset-Valorant { Write-Log -Message 'Valorant reset placeholder.' }

function Optimize-CSLegacy {
    $autoexec = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Half-Life\cstrike\autoexec.cfg"
    '@
    fps_max 300
    cl_cmdrate 101
    cl_updaterate 101
    r_drawviewmodel 0
    '@ | Set-Content -Path $autoexec
    Write-Log -Message 'CS 1.6 optimized.'
}
function Reset-CSLegacy { Write-Log -Message 'CS 1.6 reset placeholder.' }

function Optimize-CSGO {
    $autoexec = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Counter-Strike Global Offensive\csgo\cfg\autoexec.cfg"
    '@
    fps_max 400
    mat_queue_mode 2
    cl_interp_ratio 1
    '@ | Set-Content -Path $autoexec
    Write-Log -Message 'CSGO optimized.'
}
function Reset-CSGO { Write-Log -Message 'CSGO reset placeholder.' }

function Optimize-LoL {
    $config = "${env:LOCALAPPDATA}\Riot Games\League of Legends\Config\game.cfg"
    Set-IniValue -Path $config -Key 'EnableShadow' -Value '0'
    Set-IniValue -Path $config -Key 'EnableFXAA' -Value '0'
    Write-Log -Message 'LoL optimized.'
}
function Reset-LoL { Write-Log -Message 'LoL reset placeholder.' }

function Optimize-Dota2 {
    $autoexec = "${env:ProgramFiles(x86)}\Steam\steamapps\common\dota 2 beta\game\dota\cfg\autoexec.cfg"
    '@
    fps_max 240
    mat_phong 0
    r_deferred_height_fog 0
    '@ | Set-Content -Path $autoexec
    Write-Log -Message 'Dota 2 optimized.'
}
function Reset-Dota2 { Write-Log -Message 'Dota 2 reset placeholder.' }

function Optimize-Fortnite {
    $scalability = "${env:LOCALAPPDATA}\FortniteGame\Saved\Config\WindowsClient\Scalability.ini"
    Set-IniValue -Path $scalability -Key 'sg.ViewDistanceQuality' -Value '0'
    Set-IniValue -Path $scalability -Key 'sg.ShadowQuality' -Value '0'
    Write-Log -Message 'Fortnite optimized.'
}
function Reset-Fortnite { Write-Log -Message 'Fortnite reset placeholder.' }

function Optimize-Minecraft {
    $options = "${env:APPDATA}\.minecraft\options.txt"
    Set-IniValue -Path $options -Key 'fancyGraphics' -Value 'false'
    Set-IniValue -Path $options -Key 'renderDistance' -Value '8'
    Write-Log -Message 'Minecraft optimized.'
}
function Reset-Minecraft { Write-Log -Message 'Minecraft reset placeholder.' }

function Optimize-Roblox {
    New-Item -Path 'HKCU:\Software\Roblox\RobloxStudio' -Force | Out-Null
    Set-ItemProperty -Path 'HKCU:\Software\Roblox\RobloxStudio' -Name 'RenderingQuality' -Type DWord -Value 1
    Write-Log -Message 'Roblox optimized.'
}
function Reset-Roblox { Write-Log -Message 'Roblox reset placeholder.' }

function Optimize-RocketLeague {
    $config = "${env:USERPROFILE}\Documents\My Games\Rocket League\TAGame\Config\TASettings.ini"
    Set-IniValue -Path $config -Key 'VSync' -Value 'False'
    Set-IniValue -Path $config -Key 'FPS' -Value '240'
    Write-Log -Message 'Rocket League optimized.'
}
function Reset-RocketLeague { Write-Log -Message 'Rocket League reset placeholder.' }

function Optimize-TF2 {
    $autoexec = "${env:ProgramFiles(x86)}\Steam\steamapps\common\Team Fortress 2\tf\cfg\autoexec.cfg"
    '@
    mat_queue_mode 2
    cl_detaildist 0
    r_drawdetailprops 0
    '@ | Set-Content -Path $autoexec
    Write-Log -Message 'TF2 optimized.'
}
function Reset-TF2 { Write-Log -Message 'TF2 reset placeholder.' }

function Optimize-Stardew {
    $config = "${env:APPDATA}\StardewValley\startup_preferences"
    Set-IniValue -Path $config -Key 'fullscreen' -Value 'true'
    Set-IniValue -Path $config -Key 'vsync' -Value 'false'
    Write-Log -Message 'Stardew optimized.'
}
function Reset-Stardew { Write-Log -Message 'Stardew reset placeholder.' }

function Optimize-AmongUs {
    $config = "${env:LOCALAPPDATA}\Among Us\settings" 
    Set-IniValue -Path $config -Key 'VSync' -Value '0'
    Write-Log -Message 'Among Us optimized.'
}
function Reset-AmongUs { Write-Log -Message 'Among Us reset placeholder.' }

function Optimize-Trackmania {
    $config = "${env:USERPROFILE}\Documents\Trackmania\Config\Default.json"
    if (Test-Path $config) {
        $json = Get-Content $config | ConvertFrom-Json
        $json.GraphicsQuality = 'Low'
        $json | ConvertTo-Json -Depth 4 | Set-Content -Path $config
    }
    Write-Log -Message 'Trackmania optimized.'
}
function Reset-Trackmania { Write-Log -Message 'Trackmania reset placeholder.' }

function Optimize-Overwatch {
    $config = "${env:USERPROFILE}\Documents\Overwatch\Settings\Settings_v0.ini"
    Set-IniValue -Path $config -Key 'Fullscreen' -Value '1'
    Set-IniValue -Path $config -Key 'RenderScale' -Value '50'
    Write-Log -Message 'Overwatch 2 optimized.'
}
function Reset-Overwatch { Write-Log -Message 'Overwatch 2 reset placeholder.' }

function Optimize-Crossfire {
    $config = "${env:USERPROFILE}\Documents\CrossFire\Config\config.ini"
    Set-IniValue -Path $config -Key 'Quality' -Value '0'
    Write-Log -Message 'Crossfire optimized.'
}
function Reset-Crossfire { Write-Log -Message 'Crossfire reset placeholder.' }
