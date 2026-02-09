function Get-LinaGameProfiles {
    param([string]$Language = 'pt-BR')
    $profiles = @(
        @{ Key = 'FiveM'; NamePT = 'FiveM'; NameEN = 'FiveM'; DescPT = 'Cache, CitizenFX.ini, streaming e rede.'; DescEN = 'Cache, CitizenFX.ini, streaming and network.' },
        @{ Key = 'GTAV'; NamePT = 'GTA V'; NameEN = 'GTA V'; DescPT = 'Ajustes de graphics e cache.'; DescEN = 'Graphics tweaks and cache.' },
        @{ Key = 'Valorant'; NamePT = 'Valorant'; NameEN = 'Valorant'; DescPT = 'Config, prioridade e cache.'; DescEN = 'Config, priority and cache.' },
        @{ Key = 'CS2'; NamePT = 'CS2'; NameEN = 'CS2'; DescPT = 'Autoexec e launch args.'; DescEN = 'Autoexec and launch args.' },
        @{ Key = 'CSGO'; NamePT = 'CS:GO'; NameEN = 'CS:GO'; DescPT = 'Autoexec e launch args.'; DescEN = 'Autoexec and launch args.' },
        @{ Key = 'LoL'; NamePT = 'League of Legends'; NameEN = 'League of Legends'; DescPT = 'Config low e cache.'; DescEN = 'Low config and cache.' },
        @{ Key = 'Fortnite'; NamePT = 'Fortnite'; NameEN = 'Fortnite'; DescPT = 'Scalability e shader cache.'; DescEN = 'Scalability and shader cache.' },
        @{ Key = 'Minecraft'; NamePT = 'Minecraft'; NameEN = 'Minecraft'; DescPT = 'Options, JVM flags e RAM.'; DescEN = 'Options, JVM flags and RAM.' },
        @{ Key = 'Roblox'; NamePT = 'Roblox'; NameEN = 'Roblox'; DescPT = 'Registry, cache e FPS.'; DescEN = 'Registry, cache and FPS.' },
        @{ Key = 'RocketLeague'; NamePT = 'Rocket League'; NameEN = 'Rocket League'; DescPT = 'TASettings, FPS unlock.'; DescEN = 'TASettings, FPS unlock.' },
        @{ Key = 'Overwatch2'; NamePT = 'Overwatch 2'; NameEN = 'Overwatch 2'; DescPT = 'Config low e cache.'; DescEN = 'Low config and cache.' },
        @{ Key = 'Apex'; NamePT = 'Apex Legends'; NameEN = 'Apex Legends'; DescPT = 'Config low e cache.'; DescEN = 'Low config and cache.' },
        @{ Key = 'Warzone'; NamePT = 'Warzone'; NameEN = 'Warzone'; DescPT = 'Config, shaders e cache.'; DescEN = 'Config, shaders and cache.' },
        @{ Key = 'TF2'; NamePT = 'Team Fortress 2'; NameEN = 'Team Fortress 2'; DescPT = 'Autoexec e launch args.'; DescEN = 'Autoexec and launch args.' },
        @{ Key = 'Dota2'; NamePT = 'Dota 2'; NameEN = 'Dota 2'; DescPT = 'Autoexec e launch args.'; DescEN = 'Autoexec and launch args.' }
    )

    foreach ($p in $profiles) {
        $installed = Test-LinaGameInstalled -GameKey $p.Key
        $p.DetectLabel = if ($installed) { 'Detectado / Detected' } else { 'Não detectado / Not detected' }
    }

    $profiles | ForEach-Object {
        [pscustomobject]@{
            Key = $_.Key
            Name = if ($Language -eq 'pt-BR') { $_.NamePT } else { $_.NameEN }
            Description = if ($Language -eq 'pt-BR') { $_.DescPT } else { $_.DescEN }
            DetectLabel = $_.DetectLabel
        }
    }
}

function Get-LinaSteamLibraries {
    $paths = @()
    $steamPath = "$env:ProgramFiles(x86)\Steam\steamapps\libraryfolders.vdf"
    if (Test-Path $steamPath) {
        $content = Get-Content $steamPath
        foreach ($line in $content) {
            if ($line -match '"path"\s+"(.+?)"') {
                $paths += $Matches[1] -replace '\\\\','\\'
            }
        }
    }
    return $paths
}

function Get-LinaEpicInstalls {
    $installs = @()
    $manifestRoot = "$env:ProgramData\Epic\EpicGamesLauncher\Data\Manifests"
    if (Test-Path $manifestRoot) {
        Get-ChildItem -Path $manifestRoot -Filter '*.item' | ForEach-Object {
            try {
                $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
                if ($json.InstallLocation) {
                    $installs += $json.InstallLocation
                }
            } catch {
            }
        }
    }
    return $installs
}

function Get-LinaRockstarInstalls {
    $installs = @()
    $launcherFile = "$env:ProgramData\Rockstar Games\Launcher\LauncherInstalled.dat"
    if (Test-Path $launcherFile) {
        try {
            $json = Get-Content $launcherFile -Raw | ConvertFrom-Json
            foreach ($item in $json.InstallationList) {
                if ($item.InstallLocation) {
                    $installs += $item.InstallLocation
                }
            }
        } catch {
        }
    }
    return $installs
}

function Get-LinaRiotInstalls {
    $paths = @()
    $riotRoot = "$env:ProgramData\Riot Games"
    if (Test-Path $riotRoot) {
        Get-ChildItem -Path $riotRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $paths += $_.FullName
        }
    }
    return $paths
}

function Get-LinaBattleNetInstalls {
    $paths = @()
    $config = "$env:ProgramData\Battle.net\Battle.net.config"
    if (Test-Path $config) {
        try {
            $json = Get-Content $config -Raw | ConvertFrom-Json
            foreach ($entry in $json.Client.Install) {
                if ($entry.InstallDir) {
                    $paths += $entry.InstallDir
                }
            }
        } catch {
        }
    }
    return $paths
}

function Get-LinaGamePaths {
    param([string]$GameKey)

    $steamLibraries = Get-LinaSteamLibraries
    $epicInstalls = Get-LinaEpicInstalls
    $rockstarInstalls = Get-LinaRockstarInstalls
    $riotInstalls = Get-LinaRiotInstalls
    $bnetInstalls = Get-LinaBattleNetInstalls
    $manualPaths = Get-LinaManualGamePaths -GameKey $GameKey

    switch ($GameKey) {
        'FiveM' { return @("$env:LOCALAPPDATA\FiveM", "$env:APPDATA\FiveM") + $manualPaths }
        'GTAV' { return @("$env:ProgramFiles\Rockstar Games\Grand Theft Auto V", "$env:ProgramFiles(x86)\Steam\steamapps\common\Grand Theft Auto V") + $rockstarInstalls + $manualPaths }
        'Valorant' { return @("$env:ProgramFiles\Riot Vanguard", "$env:LOCALAPPDATA\VALORANT") + $riotInstalls + $manualPaths }
        'CS2' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\Counter-Strike Global Offensive' }) + $manualPaths }
        'CSGO' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\Counter-Strike Global Offensive' }) + $manualPaths }
        'LoL' { return @("$env:ProgramFiles\Riot Games\League of Legends") + $riotInstalls + $manualPaths }
        'Dota2' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\dota 2 beta") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\dota 2 beta' }) + $manualPaths }
        'Fortnite' { return @("$env:ProgramFiles\Epic Games\Fortnite") + $epicInstalls + $manualPaths }
        'Minecraft' { return @("$env:APPDATA\.minecraft") + $manualPaths }
        'Roblox' { return @("$env:LOCALAPPDATA\Roblox") + $manualPaths }
        'RocketLeague' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\rocketleague") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\rocketleague' }) + $epicInstalls + $manualPaths }
        'Overwatch2' { return @("$env:ProgramFiles (x86)\Overwatch", "$env:ProgramFiles (x86)\Battle.net") + $bnetInstalls + $manualPaths }
        'Apex' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Apex Legends") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\Apex Legends' }) + $manualPaths }
        'Warzone' { return @("$env:ProgramFiles (x86)\Call of Duty", "$env:USERPROFILE\Documents\Call of Duty") + $bnetInstalls + $manualPaths }
        'TF2' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Team Fortress 2") + ($steamLibraries | ForEach-Object { Join-Path $_ 'steamapps\common\Team Fortress 2' }) + $manualPaths }
        default { return @() }
    }
}

function Get-LinaManualGamePaths {
    param([string]$GameKey)
    $baseRoot = Get-LinaAppRoot
    if (-not $baseRoot) {
        return @()
    }
    $file = Join-Path $baseRoot 'logs\manual-games.json'
    if (-not (Test-Path $file)) {
        return @()
    }
    try {
        $json = Get-Content $file -Raw | ConvertFrom-Json
        if ($json.$GameKey) {
            return @($json.$GameKey)
        }
    } catch {
    }
    return @()
}

function Get-LinaAppRoot {
    if ($PSScriptRoot) {
        return (Split-Path -Parent $PSScriptRoot)
    }
    if ($env:LINA_APPROOT) {
        return $env:LINA_APPROOT
    }
    return $null
}

function Set-LinaGameQuality {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey,
        [Parameter(Mandatory)] [ValidateSet('Low','Medium','High')] [string]$Quality
    )

    switch ($GameKey) {
        'Valorant' { Set-LinaValorantQuality -Quality $Quality }
        'Fortnite' { Set-LinaFortniteQuality -Quality $Quality }
        'GTAV' { Set-LinaGTAVQuality -Quality $Quality }
        'FiveM' { Set-LinaFiveMQuality -Quality $Quality }
        'Minecraft' { Set-LinaMinecraftQuality -Quality $Quality }
        'Roblox' { Set-LinaRobloxQuality -Quality $Quality }
        'RocketLeague' { Set-LinaRocketLeagueQuality -Quality $Quality }
        'CS2' { Set-LinaCSQuality -Quality $Quality }
        'CSGO' { Set-LinaCSQuality -Quality $Quality }
        'Dota2' { Set-LinaDotaQuality -Quality $Quality }
        'LoL' { Set-LinaLoLQuality -Quality $Quality }
        'TF2' { Set-LinaCSQuality -Quality $Quality }
        default { }
    }
}

function Set-LinaValorantQuality {
    param([string]$Quality)
    $configPath = "$env:LOCALAPPDATA\VALORANT\Saved\Config\Windows\GameUserSettings.ini"
    if (-not (Test-Path $configPath)) { return }
    $settings = switch ($Quality) {
        'Low' { @{ 'OverallScalabilityLevel' = '1'; 'bUseVSync' = 'False' } }
        'Medium' { @{ 'OverallScalabilityLevel' = '2'; 'bUseVSync' = 'False' } }
        'High' { @{ 'OverallScalabilityLevel' = '3'; 'bUseVSync' = 'True' } }
    }
    foreach ($key in $settings.Keys) {
        Set-LinaIniValue -Path $configPath -Key $key -Value $settings[$key]
    }
}

function Set-LinaFortniteQuality {
    param([string]$Quality)
    $configPath = "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
    if (-not (Test-Path $configPath)) { return }
    $settings = switch ($Quality) {
        'Low' { @{ 'sg.ViewDistanceQuality' = '0'; 'sg.ShadowQuality' = '0'; 'sg.TextureQuality' = '0'; 'sg.EffectsQuality' = '0' } }
        'Medium' { @{ 'sg.ViewDistanceQuality' = '2'; 'sg.ShadowQuality' = '2'; 'sg.TextureQuality' = '2'; 'sg.EffectsQuality' = '2' } }
        'High' { @{ 'sg.ViewDistanceQuality' = '3'; 'sg.ShadowQuality' = '3'; 'sg.TextureQuality' = '3'; 'sg.EffectsQuality' = '3' } }
    }
    foreach ($key in $settings.Keys) {
        Set-LinaIniValue -Path $configPath -Key $key -Value $settings[$key]
    }
}

function Set-LinaGTAVQuality {
    param([string]$Quality)
    $settings = "$env:USERPROFILE\Documents\Rockstar Games\GTA V\settings.xml"
    if (-not (Test-Path $settings)) { return }
    $value = switch ($Quality) {
        'Low' { '0' }
        'Medium' { '2' }
        'High' { '4' }
    }
    (Get-Content $settings) | ForEach-Object { $_ -replace 'ShadowQuality value="\d+"', "ShadowQuality value=`"$value`"" } | Set-Content $settings
}

function Set-LinaFiveMQuality {
    param([string]$Quality)
    $configPath = "$env:APPDATA\CitizenFX\fivem.cfg"
    if (-not (Test-Path $configPath)) { return }
    $value = switch ($Quality) { 'Low' { '0' } 'Medium' { '1' } 'High' { '2' } }
    Set-LinaConfigValue -Path $configPath -Key 'profile_gpu' -Value $value
}

function Set-LinaMinecraftQuality {
    param([string]$Quality)
    $options = "$env:APPDATA\.minecraft\options.txt"
    if (-not (Test-Path $options)) { return }
    $distance = switch ($Quality) { 'Low' { '6' } 'Medium' { '10' } 'High' { '16' } }
    $fancy = switch ($Quality) { 'Low' { 'false' } 'Medium' { 'true' } 'High' { 'true' } }
    Set-LinaConfigValue -Path $options -Key 'renderDistance' -Value $distance
    Set-LinaConfigValue -Path $options -Key 'fancyGraphics' -Value $fancy
}

function Set-LinaRobloxQuality {
    param([string]$Quality)
    $value = switch ($Quality) { 'Low' { 1 } 'Medium' { 4 } 'High' { 8 } }
    New-ItemProperty -Path 'HKCU:\Software\Roblox' -Name 'DFIntGraphicsQualityOverride' -Value $value -PropertyType DWord -Force | Out-Null
}

function Set-LinaRocketLeagueQuality {
    param([string]$Quality)
    $configPath = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini"
    if (-not (Test-Path $configPath)) { return }
    $value = switch ($Quality) { 'Low' { '0' } 'Medium' { '2' } 'High' { '3' } }
    Set-LinaIniValue -Path $configPath -Key 'DetailMode' -Value $value
}

function Set-LinaCSQuality {
    param([string]$Quality)
    $autoexec = "$env:APPDATA\LinaOptimizer\autoexec.cfg"
    if (-not (Test-Path $autoexec)) { return }
    $preset = switch ($Quality) {
        'Low' { 'r_texturequality 0' }
        'Medium' { 'r_texturequality 1' }
        'High' { 'r_texturequality 2' }
    }
    Add-Content -Path $autoexec -Value $preset
}

function Set-LinaDotaQuality {
    param([string]$Quality)
    $autoexec = "$env:APPDATA\LinaOptimizer\dota_autoexec.cfg"
    if (-not (Test-Path $autoexec)) { return }
    $value = switch ($Quality) { 'Low' { '0' } 'Medium' { '1' } 'High' { '2' } }
    Add-Content -Path $autoexec -Value "r_texture_stream_mip_bias $value"
}

function Set-LinaLoLQuality {
    param([string]$Quality)
    $configPath = "$env:LOCALAPPDATA\Riot Games\League of Legends\Config\game.cfg"
    if (-not (Test-Path $configPath)) { return }
    $value = switch ($Quality) { 'Low' { '1' } 'Medium' { '3' } 'High' { '5' } }
    Set-LinaIniValue -Path $configPath -Key 'GraphicsQuality' -Value $value
}

function Test-LinaGameInstalled {
    param([string]$GameKey)
    $paths = Get-LinaGamePaths -GameKey $GameKey
    foreach ($p in $paths) {
        if ($p -and (Test-Path $p)) {
            return $true
        }
    }
    return $false
}

function Invoke-LinaGameOptimization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey
    )

    switch ($GameKey) {
        'FiveM' { Optimize-LinaFiveM }
        'GTAV' { Optimize-LinaGTAV }
        'Valorant' { Optimize-LinaValorant }
        'CS2' { Optimize-LinaCS }
        'CSGO' { Optimize-LinaCS }
        'LoL' { Optimize-LinaLoL }
        'Dota2' { Optimize-LinaDota2 }
        'Fortnite' { Optimize-LinaFortnite }
        'Minecraft' { Optimize-LinaMinecraft }
        'Roblox' { Optimize-LinaRoblox }
        'RocketLeague' { Optimize-LinaRocketLeague }
        'Overwatch2' { Optimize-LinaGeneric -GameKey $GameKey }
        'Apex' { Optimize-LinaGeneric -GameKey $GameKey }
        'Warzone' { Optimize-LinaGeneric -GameKey $GameKey }
        'TF2' { Optimize-LinaCS }
    }
}

function Reset-LinaGameOptimization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey
    )

    if ($PSCmdlet.ShouldProcess($GameKey, 'Reset configs')) {
        $paths = Get-LinaGamePaths -GameKey $GameKey
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Get-ChildItem -Path $p -Include '*.ini','*.cfg','*.txt' -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Optimize-LinaFiveM {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $configPath = "$env:APPDATA\CitizenFX\fivem.cfg"
    $cachePath = "$env:LOCALAPPDATA\FiveM\FiveM.app\cache"

    if ($PSCmdlet.ShouldProcess('FiveM', 'Tweak')) {
        if (Test-Path $configPath) {
            Set-LinaConfigValue -Path $configPath -Key 'cl_drawperf' -Value '1'
            Set-LinaConfigValue -Path $configPath -Key 'cl_drawfps' -Value '1'
        }
        if (Test-Path $cachePath) {
            Remove-Item -Path $cachePath -Recurse -Force -ErrorAction SilentlyContinue
        }
        Set-ProcessPriority -ProcessName 'FiveM' -Priority 'High'
    }
}

function Optimize-LinaGTAV {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $settings = "$env:USERPROFILE\Documents\Rockstar Games\GTA V\settings.xml"
    if ($PSCmdlet.ShouldProcess('GTA V', 'Tweak')) {
        if (Test-Path $settings) {
            (Get-Content $settings) |
                ForEach-Object { $_ -replace 'ShadowQuality value="\d+"', 'ShadowQuality value="0"' } |
                Set-Content $settings
        }
        Set-ProcessPriority -ProcessName 'GTA5' -Priority 'High'
    }
}

function Optimize-LinaValorant {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\VALORANT\Saved\Config\Windows\GameUserSettings.ini"
    if ($PSCmdlet.ShouldProcess('Valorant', 'Tweak')) {
        if (Test-Path $configPath) {
            Set-LinaIniValue -Path $configPath -Key 'bUseVSync' -Value 'False'
            Set-LinaIniValue -Path $configPath -Key 'bShouldUseFullscreen' -Value 'True'
        }
        Set-ProcessPriority -ProcessName 'VALORANT-Win64-Shipping' -Priority 'High'
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaCS {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $autoexec = "$env:APPDATA\LinaOptimizer\autoexec.cfg"
    if ($PSCmdlet.ShouldProcess('CS/TF2', 'Tweak')) {
        New-Item -Path (Split-Path $autoexec -Parent) -ItemType Directory -Force | Out-Null
        @(
            'fps_max 300',
            'mat_queue_mode 2',
            'r_drawtracers_firstperson 0',
            'cl_forcepreload 1',
            'cl_disablehtmlmotd 1'
        ) | Set-Content $autoexec
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaMinecraft {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $options = "$env:APPDATA\.minecraft\options.txt"
    if ($PSCmdlet.ShouldProcess('Minecraft', 'Tweak')) {
        if (Test-Path $options) {
            Set-LinaConfigValue -Path $options -Key 'fancyGraphics' -Value 'false'
            Set-LinaConfigValue -Path $options -Key 'renderDistance' -Value '8'
            Set-LinaConfigValue -Path $options -Key 'particles' -Value '2'
        }
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaRoblox {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if ($PSCmdlet.ShouldProcess('Roblox', 'Tweak')) {
        New-ItemProperty -Path 'HKCU:\Software\Roblox' -Name 'DFIntTaskSchedulerTargetFps' -Value 120 -PropertyType DWord -Force | Out-Null
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaFortnite {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
    if ($PSCmdlet.ShouldProcess('Fortnite', 'Tweak')) {
        if (Test-Path $configPath) {
            Set-LinaIniValue -Path $configPath -Key 'bUseVSync' -Value 'False'
            Set-LinaIniValue -Path $configPath -Key 'FrameRateLimit' -Value '240.000000'
        }
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaRocketLeague {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini"
    if ($PSCmdlet.ShouldProcess('RocketLeague', 'Tweak')) {
        if (Test-Path $configPath) {
            Set-LinaIniValue -Path $configPath -Key 'bVSync' -Value 'False'
        }
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaLoL {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\Riot Games\League of Legends\Config\game.cfg"
    if ($PSCmdlet.ShouldProcess('LoL', 'Tweak')) {
        if (Test-Path $configPath) {
            Set-LinaIniValue -Path $configPath -Key 'GraphicsQuality' -Value '1'
            Set-LinaIniValue -Path $configPath -Key 'CharacterQuality' -Value '1'
        }
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaDota2 {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $autoexec = "$env:APPDATA\LinaOptimizer\dota_autoexec.cfg"
    if ($PSCmdlet.ShouldProcess('Dota2', 'Tweak')) {
        New-Item -Path (Split-Path $autoexec -Parent) -ItemType Directory -Force | Out-Null
        @(
            'fps_max 240',
            'dota_disable_range_finder 1',
            'dota_minimap_hero_size 600',
            'r_texture_stream_mip_bias 1'
        ) | Set-Content $autoexec
        Invoke-LinaGameCacheCleanup
    }
}

function Optimize-LinaGeneric {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey
    )
    if ($PSCmdlet.ShouldProcess($GameKey, 'Generic Tweak')) {
        Invoke-LinaGameCacheCleanup
    }
}

function Invoke-LinaGameCacheCleanup {
    $paths = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\AMD\DxCache",
        "$env:LOCALAPPDATA\FiveM\FiveM.app\cache",
        "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\ShaderCache",
        "$env:LOCALAPPDATA\VALORANT\Saved\Logs"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
}

function Set-LinaIniValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )
    if (-not (Test-Path $Path)) {
        return
    }
    $content = Get-Content $Path
    $updated = $false
    $content = $content | ForEach-Object {
        if ($_ -match "^$Key=") {
            $updated = $true
            return "$Key=$Value"
        }
        $_
    }
    if (-not $updated) {
        $content += "$Key=$Value"
    }
    $content | Set-Content $Path
}

function Set-LinaConfigValue {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )
    if (-not (Test-Path $Path)) {
        return
    }
    $content = Get-Content $Path
    $updated = $false
    $content = $content | ForEach-Object {
        if ($_ -match "^$Key") {
            $updated = $true
            return "${Key}:$Value"
        }
        $_
    }
    if (-not $updated) {
        $content += "${Key}:$Value"
    }
    $content | Set-Content $Path
}

function Set-ProcessPriority {
    param(
        [Parameter(Mandatory)] [string]$ProcessName,
        [ValidateSet('Idle','BelowNormal','Normal','AboveNormal','High','RealTime')] [string]$Priority
    )
    Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | ForEach-Object {
        $_.PriorityClass = $Priority
    }
}
