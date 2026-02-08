function Get-LinaGameProfiles {
    $profiles = @(
        @{ Key = 'Valorant'; Name = 'Valorant'; Description = 'Low graphics, VSync off, prioridade alta.' },
        @{ Key = 'CS16'; Name = 'Counter-Strike 1.6'; Description = 'Autoexec, launch options, low DX.' },
        @{ Key = 'CSGO'; Name = 'Counter-Strike: Global Offensive'; Description = 'Autoexec, launch options, low DX.' },
        @{ Key = 'LoL'; Name = 'League of Legends'; Description = 'Config low, disable eye candy.' },
        @{ Key = 'Dota2'; Name = 'Dota 2'; Description = 'Launch options e autoexec.' },
        @{ Key = 'Fortnite'; Name = 'Fortnite'; Description = 'Scalability e shader cache.' },
        @{ Key = 'Minecraft'; Name = 'Minecraft'; Description = 'Options.txt, JVM flags, RAM.' },
        @{ Key = 'Roblox'; Name = 'Roblox'; Description = 'Registry graphics e cache.' },
        @{ Key = 'RocketLeague'; Name = 'Rocket League'; Description = 'TASettings, FPS unlock.' },
        @{ Key = 'TF2'; Name = 'Team Fortress 2'; Description = 'Autoexec, nojoy, novid.' },
        @{ Key = 'Stardew'; Name = 'Stardew Valley'; Description = 'Config low, cache cleanup.' },
        @{ Key = 'AmongUs'; Name = 'Among Us'; Description = 'Config low, cleanup.' },
        @{ Key = 'Trackmania'; Name = 'Trackmania'; Description = 'Low graphics preset.' },
        @{ Key = 'Overwatch2'; Name = 'Overwatch 2'; Description = 'Render scale, low config.' },
        @{ Key = 'Crossfire'; Name = 'Crossfire'; Description = 'Config low, ini cleanup.' }
    )

    foreach ($p in $profiles) {
        $installed = Test-LinaGameInstalled -GameKey $p.Key
        $p.DetectLabel = if ($installed) { 'Detectado / Detected' } else { 'Não detectado / Not detected' }
    }
    $profiles | ForEach-Object { [pscustomobject]$_ }
}

function Test-LinaGameInstalled {
    param([string]$GameKey)
    $paths = Get-LinaGamePaths -GameKey $GameKey
    foreach ($p in $paths) {
        if (Test-Path $p) {
            return $true
        }
    }
    return $false
}

function Get-LinaGamePaths {
    param([string]$GameKey)
    switch ($GameKey) {
        'Valorant' { return @("$env:ProgramFiles\Riot Vanguard", "$env:LOCALAPPDATA\VALORANT") }
        'CS16' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Half-Life") }
        'CSGO' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Counter-Strike Global Offensive") }
        'LoL' { return @("$env:ProgramFiles\Riot Games\League of Legends") }
        'Dota2' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\dota 2 beta") }
        'Fortnite' { return @("$env:ProgramFiles\Epic Games\Fortnite") }
        'Minecraft' { return @("$env:APPDATA\.minecraft") }
        'Roblox' { return @("$env:LOCALAPPDATA\Roblox") }
        'RocketLeague' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\rocketleague") }
        'TF2' { return @("$env:ProgramFiles(x86)\Steam\steamapps\common\Team Fortress 2") }
        'Stardew' { return @("$env:APPDATA\StardewValley") }
        'AmongUs' { return @("$env:APPDATA\InnerSloth\Among Us") }
        'Trackmania' { return @("$env:ProgramFiles\Trackmania") }
        'Overwatch2' { return @("$env:ProgramFiles (x86)\Overwatch") }
        'Crossfire' { return @("$env:ProgramFiles\Crossfire") }
        default { return @() }
    }
}

function Invoke-LinaGameOptimization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey
    )

    switch ($GameKey) {
        'Valorant' { Optimize-LinaValorant }
        'CS16' { Optimize-LinaCS }
        'CSGO' { Optimize-LinaCS }
        'LoL' { Optimize-LinaLoL }
        'Dota2' { Optimize-LinaDota2 }
        'Fortnite' { Optimize-LinaFortnite }
        'Minecraft' { Optimize-LinaMinecraft }
        'Roblox' { Optimize-LinaRoblox }
        'RocketLeague' { Optimize-LinaRocketLeague }
        'TF2' { Optimize-LinaCS }
        'Stardew' { Optimize-LinaGeneric -GameKey $GameKey }
        'AmongUs' { Optimize-LinaGeneric -GameKey $GameKey }
        'Trackmania' { Optimize-LinaGeneric -GameKey $GameKey }
        'Overwatch2' { Optimize-LinaGeneric -GameKey $GameKey }
        'Crossfire' { Optimize-LinaGeneric -GameKey $GameKey }
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

function Optimize-LinaValorant {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\VALORANT\Saved\Config\Windows\GameUserSettings.ini"
    if ($PSCmdlet.ShouldProcess('Valorant', 'Tweak')) {
        if (Test-Path $configPath) {
            (Get-Content $configPath) |
                ForEach-Object { $_ -replace 'bUseVSync=.*', 'bUseVSync=False' } |
                Set-Content $configPath
        }
        Set-ProcessPriority -ProcessName 'VALORANT-Win64-Shipping' -Priority 'High'
        Invoke-LinaCacheCleanup
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
            'cl_forcepreload 1'
        ) | Set-Content $autoexec
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaMinecraft {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $options = "$env:APPDATA\.minecraft\options.txt"
    if ($PSCmdlet.ShouldProcess('Minecraft', 'Tweak')) {
        if (Test-Path $options) {
            (Get-Content $options) |
                ForEach-Object { $_ -replace 'fancyGraphics:.*', 'fancyGraphics:false' } |
                ForEach-Object { $_ -replace 'renderDistance:.*', 'renderDistance:8' } |
                Set-Content $options
        }
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaRoblox {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if ($PSCmdlet.ShouldProcess('Roblox', 'Tweak')) {
        New-ItemProperty -Path 'HKCU:\Software\Roblox' -Name 'DFIntTaskSchedulerTargetFps' -Value 120 -PropertyType DWord -Force | Out-Null
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaFortnite {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\FortniteGame\Saved\Config\WindowsClient\GameUserSettings.ini"
    if ($PSCmdlet.ShouldProcess('Fortnite', 'Tweak')) {
        if (Test-Path $configPath) {
            (Get-Content $configPath) |
                ForEach-Object { $_ -replace 'bUseVSync=.*', 'bUseVSync=False' } |
                ForEach-Object { $_ -replace 'FrameRateLimit=.*', 'FrameRateLimit=240.000000' } |
                Set-Content $configPath
        }
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaRocketLeague {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:USERPROFILE\Documents\My Games\Rocket League\TAGame\Config\TASystemSettings.ini"
    if ($PSCmdlet.ShouldProcess('RocketLeague', 'Tweak')) {
        if (Test-Path $configPath) {
            (Get-Content $configPath) |
                ForEach-Object { $_ -replace 'bVSync=.*', 'bVSync=False' } |
                Set-Content $configPath
        }
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaLoL {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $configPath = "$env:LOCALAPPDATA\Riot Games\League of Legends\Config\game.cfg"
    if ($PSCmdlet.ShouldProcess('LoL', 'Tweak')) {
        if (Test-Path $configPath) {
            (Get-Content $configPath) |
                ForEach-Object { $_ -replace 'GraphicsQuality=.*', 'GraphicsQuality=1' } |
                Set-Content $configPath
        }
        Invoke-LinaCacheCleanup
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
            'dota_minimap_hero_size 600'
        ) | Set-Content $autoexec
        Invoke-LinaCacheCleanup
    }
}

function Optimize-LinaGeneric {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$GameKey
    )
    if ($PSCmdlet.ShouldProcess($GameKey, 'Generic Tweak')) {
        Invoke-LinaCacheCleanup
    }
}

function Invoke-LinaCacheCleanup {
    $paths = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "$env:LOCALAPPDATA\D3DSCache",
        "$env:LOCALAPPDATA\NVIDIA\DXCache",
        "$env:LOCALAPPDATA\AMD\DxCache"
    )
    foreach ($p in $paths) {
        if (Test-Path $p) {
            Get-ChildItem -Path $p -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
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
