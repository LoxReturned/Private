#requires -Version 5.1
chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LogRoot = Join-Path $script:AppRoot 'logs'
if (-not (Test-Path $script:LogRoot)) {
    New-Item -Path $script:LogRoot -ItemType Directory | Out-Null
}

$script:ModuleFiles = @(
    (Join-Path $script:AppRoot 'modules\system.ps1'),
    (Join-Path $script:AppRoot 'modules\games.ps1'),
    (Join-Path $script:AppRoot 'modules\network.ps1'),
    (Join-Path $script:AppRoot 'modules\power.ps1'),
    (Join-Path $script:AppRoot 'modules\debloat.ps1'),
    (Join-Path $script:AppRoot 'modules\kernel.ps1'),
    (Join-Path $script:AppRoot 'modules\backup.ps1')
)

foreach ($module in $script:ModuleFiles) {
    . $module
}

$script:Simulation = $false
$script:Language = 'pt-BR'
$script:RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
$script:RunspacePool.Open()

function Write-LinaLog {
    param(
        [Parameter(Mandatory)] [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp][$Level] $Message"
    $logFile = Join-Path $script:LogRoot 'lina-optimizer.log'
    Add-Content -Path $logFile -Value $line
}

function Invoke-LinaRunspace {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock,
        [object[]]$Arguments = @(),
        [scriptblock]$OnComplete
    )
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $script:RunspacePool
    [void]$ps.AddScript({
        param($moduleFiles, $action, $args)
        foreach ($file in $moduleFiles) {
            . $file
        }
        & $action @args
    }).AddArgument($script:ModuleFiles).AddArgument($ScriptBlock).AddArgument($Arguments)

    $handle = $ps.BeginInvoke()
    Write-LinaLog "Task started: $Name"
    $timer = New-Object Timers.Timer
    $timer.Interval = 250
    $timer.AutoReset = $true
    $timer.add_Elapsed({
        if ($handle.IsCompleted) {
            $timer.Stop()
            $timer.Dispose()
            try {
                $null = $ps.EndInvoke($handle)
                Write-LinaLog "Task completed: $Name"
            } catch {
                Write-LinaLog "Task failed: $Name - $_" 'ERROR'
            } finally {
                $ps.Dispose()
                if ($OnComplete) {
                    $window.Dispatcher.Invoke($OnComplete)
                }
            }
        }
    })
    $timer.Start()
}

function Get-LinaStrings {
    param([string]$Language)
    if ($Language -eq 'en-US') {
        return @{
            NavDashboard = 'Dashboard'
            NavSystem = 'System'
            NavGames = 'Games'
            NavNetwork = 'Network'
            NavDebloat = 'Debloat'
            NavKernel = 'Kernel / Boot'
            NavPower = 'Power'
            NavBackup = 'Backup'
            NavAdvanced = 'Advanced'
            NavDiscord = 'Discord'
            DashboardTitle = 'Dashboard'
            SystemTitle = 'System Tweaks'
            GamesTitle = 'Game Center'
            NetworkTitle = 'Network'
            DebloatTitle = 'Windows Debloat'
            KernelTitle = 'Kernel / Boot'
            PowerTitle = 'Power'
            BackupTitle = 'Backup'
            AdvancedTitle = 'Advanced Integrations'
            DiscordTitle = 'Discord'
            HealthScoreLabel = 'Health score'
            AlertsLabel = 'Alerts & Warnings'
            DetectionLabel = 'Detection'
            OptimizeAll = 'Optimize All'
            SimToggle = 'Dry Run'
            SimulationOn = 'Dry Run ON'
            SimulationOff = 'Dry Run OFF'
            StatusReady = 'Ready'
            Continue = 'Continue'
            GameOptimize = 'Optimize'
            GameReset = 'Reset'
            Apply = 'Apply'
            Create = 'Create'
            Open = 'Open'
            Run = 'Run'
            Backup = 'Backup'
            Restore = 'Restore'
        }
    }

    return @{
        NavDashboard = 'Dashboard'
        NavSystem = 'Sistema'
        NavGames = 'Jogos'
        NavNetwork = 'Rede'
        NavDebloat = 'Debloat'
        NavKernel = 'Kernel / Boot'
        NavPower = 'Energia'
        NavBackup = 'Backup'
        NavAdvanced = 'Avançado'
        NavDiscord = 'Discord'
        DashboardTitle = 'Dashboard'
        SystemTitle = 'Sistema'
        GamesTitle = 'Game Center'
        NetworkTitle = 'Rede'
        DebloatTitle = 'Debloat Windows'
        KernelTitle = 'Kernel / Boot'
        PowerTitle = 'Energia'
        BackupTitle = 'Backup'
        AdvancedTitle = 'Integrações Avançadas'
        DiscordTitle = 'Discord'
        HealthScoreLabel = 'Health score'
        AlertsLabel = 'Alertas & Avisos'
        DetectionLabel = 'Detecção'
        OptimizeAll = 'Otimizar Tudo'
        SimToggle = 'Simulação'
        SimulationOn = 'Dry Run ON'
        SimulationOff = 'Dry Run OFF'
        StatusReady = 'Pronto'
        Continue = 'Continuar'
        GameOptimize = 'Otimizar'
        GameReset = 'Resetar'
        Apply = 'Aplicar'
        Create = 'Criar'
        Open = 'Abrir'
        Run = 'Executar'
        Backup = 'Backup'
        Restore = 'Restaurar'
    }
}

function New-LinaViewModel {
    param([string]$Language)
    $strings = Get-LinaStrings -Language $Language

    [pscustomobject]@{
        AppTitle = 'Lina Optimizer'
        Tagline = if ($Language -eq 'pt-BR') { 'Otimização profissional para Windows e jogos' } else { 'Professional optimization for Windows and games' }
        Dashboard = Get-LinaDashboardSummary
        SystemInfo = Get-LinaSystemInfoList -Language $Language
        SystemTweaks = Get-LinaSystemTweaks -Language $Language
        NetworkTweaks = Get-LinaNetworkTweaks -Language $Language
        KernelTweaks = Get-LinaKernelTweaks -Language $Language
        GameList = Get-LinaGameProfiles -Language $Language
        DebloatModes = Get-LinaDebloatModes -Language $Language
        BackupActions = Get-LinaBackupActions -Language $Language
        PowerPlan = [pscustomobject]@{
            Title = if ($Language -eq 'pt-BR') { 'Plano Lina Performance' } else { 'Lina Performance Plan' }
            Description = if ($Language -eq 'pt-BR') { 'CPU 100%, C-States off, PCIe off, USB off, GPU max.' } else { 'CPU 100%, C-States off, PCIe off, USB off, GPU max.' }
        }
        AdvancedActions = [pscustomobject]@{
            ProcessLasso = if ($Language -eq 'pt-BR') { 'Abrir Process Lasso se instalado.' } else { 'Open Process Lasso if installed.' }
            NvidiaInspector = if ($Language -eq 'pt-BR') { 'Abrir NVIDIA Profile Inspector.' } else { 'Open NVIDIA Profile Inspector.' }
            UnparkCPU = if ($Language -eq 'pt-BR') { 'Abrir Unpark CPU.' } else { 'Open Unpark CPU.' }
            ParkControl = if ($Language -eq 'pt-BR') { 'Abrir ParkControl.' } else { 'Open ParkControl.' }
            DiscordDebloat = if ($Language -eq 'pt-BR') { 'Limpar caches e arquivos do Discord.' } else { 'Clean Discord caches and files.' }
        }
        DiscordCard = [pscustomobject]@{
            Title = if ($Language -eq 'pt-BR') { 'Comunidade Lina' } else { 'Lina Community' }
            Description = if ($Language -eq 'pt-BR') { 'Entre no Discord oficial.' } else { 'Join the official Discord.' }
        }
        GameActions = [pscustomobject]@{
            Optimize = $strings.GameOptimize
            Reset = $strings.GameReset
        }
        ButtonLabels = [pscustomobject]@{
            Apply = $strings.Apply
            Create = $strings.Create
            Open = $strings.Open
            Run = $strings.Run
            OptimizeAll = $strings.OptimizeAll
            Backup = $strings.Backup
            Restore = $strings.Restore
        }
    }
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[xml]$xaml = Get-Content -Path (Join-Path $script:AppRoot 'ui.xaml') -Raw
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

function Set-UiStrings {
    param([hashtable]$Strings)
    $window.FindName('NavDashboard').Content = $Strings.NavDashboard
    $window.FindName('NavSystem').Content = $Strings.NavSystem
    $window.FindName('NavGames').Content = $Strings.NavGames
    $window.FindName('NavNetwork').Content = $Strings.NavNetwork
    $window.FindName('NavDebloat').Content = $Strings.NavDebloat
    $window.FindName('NavKernel').Content = $Strings.NavKernel
    $window.FindName('NavPower').Content = $Strings.NavPower
    $window.FindName('NavBackup').Content = $Strings.NavBackup
    $window.FindName('NavAdvanced').Content = $Strings.NavAdvanced
    $window.FindName('NavDiscord').Content = $Strings.NavDiscord
    $window.FindName('DashboardTitle').Text = $Strings.DashboardTitle
    $window.FindName('SystemTitle').Text = $Strings.SystemTitle
    $window.FindName('GamesTitle').Text = $Strings.GamesTitle
    $window.FindName('NetworkTitle').Text = $Strings.NetworkTitle
    $window.FindName('DebloatTitle').Text = $Strings.DebloatTitle
    $window.FindName('KernelTitle').Text = $Strings.KernelTitle
    $window.FindName('PowerTitle').Text = $Strings.PowerTitle
    $window.FindName('BackupTitle').Text = $Strings.BackupTitle
    $window.FindName('AdvancedTitle').Text = $Strings.AdvancedTitle
    $window.FindName('DiscordTitle').Text = $Strings.DiscordTitle
    $window.FindName('HealthScoreLabel').Text = $Strings.HealthScoreLabel
    $window.FindName('AlertsLabel').Text = $Strings.AlertsLabel
    $window.FindName('DetectionLabel').Text = $Strings.DetectionLabel
    $window.FindName('OptimizeAllButton').Content = $Strings.OptimizeAll
    $window.FindName('SimToggle').Content = $Strings.SimToggle
}

$viewModel = New-LinaViewModel -Language $script:Language
$window.DataContext = $viewModel
$strings = Get-LinaStrings -Language $script:Language
Set-UiStrings -Strings $strings
$window.FindName('StatusText').Text = $strings.StatusReady

function Set-Status {
    param([string]$Message)
    $window.Dispatcher.Invoke([action]{
        $window.FindName('StatusText').Text = $Message
    })
}

$window.Add_SourceInitialized({
    if (-not (Test-LinaAdmin)) {
        Set-Status 'Execute como Administrador / Run as Administrator'
    } else {
        Set-Status 'Admin OK'
    }
})

$window.FindName('LanguageSelector').Add_SelectionChanged({
    $item = $window.FindName('LanguageSelector').SelectedItem
    if ($item -and $item.Tag) {
        $script:Language = $item.Tag
        $viewModel = New-LinaViewModel -Language $script:Language
        $window.DataContext = $viewModel
        $strings = Get-LinaStrings -Language $script:Language
        Set-UiStrings -Strings $strings
        Set-Status $strings.StatusReady
    }
})

$window.FindName('SimToggle').Add_Checked({
    $script:Simulation = $true
    $strings = Get-LinaStrings -Language $script:Language
    Set-Status $strings.SimulationOn
})
$window.FindName('SimToggle').Add_Unchecked({
    $script:Simulation = $false
    $strings = Get-LinaStrings -Language $script:Language
    Set-Status $strings.SimulationOff
})

$window.FindName('SideMenu').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    if ($button.Tag -match '^Tab:(\d+)$') {
        $window.FindName('MainTabs').SelectedIndex = [int]$Matches[1]
    }
})

$window.FindName('SystemTweaksPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $toggle = $_.OriginalSource
    if ($toggle -isnot [System.Windows.Controls.ToggleButton]) {
        return
    }
    $key = $toggle.Tag
    if (-not $key) {
        return
    }
    $isEnabled = [bool]$toggle.IsChecked
    Set-Status "System: $key"
    Invoke-LinaRunspace -Name $key -ScriptBlock {
        param($k, $enabled, $simulation)
        Set-LinaSystemTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status 'Operação concluída / Operation completed'
    }
})

$window.FindName('NetworkTweaksPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $toggle = $_.OriginalSource
    if ($toggle -isnot [System.Windows.Controls.ToggleButton]) {
        return
    }
    $key = $toggle.Tag
    if (-not $key) {
        return
    }
    $isEnabled = [bool]$toggle.IsChecked
    Set-Status "Network: $key"
    Invoke-LinaRunspace -Name "Network-$key" -ScriptBlock {
        param($k, $enabled, $simulation)
        Set-LinaNetworkTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status 'Rede atualizada / Network updated'
    }
})

$window.FindName('KernelTweaksPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $toggle = $_.OriginalSource
    if ($toggle -isnot [System.Windows.Controls.ToggleButton]) {
        return
    }
    $key = $toggle.Tag
    if (-not $key) {
        return
    }
    $isEnabled = [bool]$toggle.IsChecked
    Set-Status "Kernel: $key"
    Invoke-LinaRunspace -Name "Kernel-$key" -ScriptBlock {
        param($k, $enabled, $simulation)
        Set-LinaKernelTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status 'Kernel atualizado / Kernel updated'
    }
})

$window.FindName('GamesPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    $action = $button.Tag
    $gameKey = $button.CommandParameter
    if (-not $gameKey) {
        return
    }
    if ($action -eq 'Optimize') {
        Set-Status "Game: $gameKey"
        Invoke-LinaRunspace -Name "Game-$gameKey-Optimize" -ScriptBlock {
            param($k, $simulation)
            Invoke-LinaGameOptimization -GameKey $k -WhatIf:$simulation
        } -Arguments @($gameKey, $script:Simulation) -OnComplete {
            Set-Status 'Game otimizado / Game optimized'
        }
    }
    if ($action -eq 'Reset') {
        Set-Status "Game reset: $gameKey"
        Invoke-LinaRunspace -Name "Game-$gameKey-Reset" -ScriptBlock {
            param($k, $simulation)
            Reset-LinaGameOptimization -GameKey $k -WhatIf:$simulation
        } -Arguments @($gameKey, $script:Simulation) -OnComplete {
            Set-Status 'Game resetado / Game reset'
        }
    }
})

$window.FindName('DebloatPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    if ($button.Tag -match '^Debloat:(\w+)$') {
        $mode = $Matches[1]
        Set-Status "Debloat: $mode"
        Invoke-LinaRunspace -Name "Debloat-$mode" -ScriptBlock {
            param($m, $simulation)
            Invoke-LinaDebloat -Mode $m -WhatIf:$simulation
        } -Arguments @($mode, $script:Simulation) -OnComplete {
            Set-Status 'Debloat concluído / Debloat completed'
        }
    }
})

$window.FindName('PowerPlanButton').Add_Click({
    Set-Status 'Power plan'
    Invoke-LinaRunspace -Name 'PowerPlan' -ScriptBlock {
        param($simulation)
        New-LinaPowerPlan -WhatIf:$simulation
    } -Arguments @($script:Simulation) -OnComplete {
        Set-Status 'Plano aplicado / Plan applied'
    }
})

$window.FindName('BackupPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    switch ($button.Tag) {
        'RestorePoint' {
            Set-Status 'Restore point'
            Invoke-LinaRunspace -Name 'RestorePoint' -ScriptBlock {
                param($simulation)
                New-LinaRestorePoint -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status 'Restore point criado / Restore point created'
            }
        }
        'BackupRegistry' {
            Set-Status 'Backup registry'
            Invoke-LinaRunspace -Name 'BackupRegistry' -ScriptBlock {
                param($simulation)
                Backup-LinaRegistry -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status 'Backup concluído / Backup completed'
            }
        }
        'BackupConfigs' {
            Set-Status 'Backup configs'
            Invoke-LinaRunspace -Name 'BackupConfigs' -ScriptBlock {
                param($simulation)
                Backup-LinaGameConfigs -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status 'Backup concluído / Backup completed'
            }
        }
        'RestoreAll' {
            Set-Status 'Restore all'
            Invoke-LinaRunspace -Name 'RestoreAll' -ScriptBlock {
                param($simulation)
                Restore-LinaAll -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status 'Restauração finalizada / Restore finished'
            }
        }
    }
})

$window.FindName('OptimizeAllButton').Add_Click({
    Set-Status 'Optimize all'
    Invoke-LinaRunspace -Name 'OptimizeAll' -ScriptBlock {
        param($simulation)
        $catalog = Get-LinaSystemTweakCatalog
        foreach ($key in $catalog.Keys) {
            Set-LinaSystemTweak -Key $key -Enabled -WhatIf:$simulation
        }
    } -Arguments @($script:Simulation) -OnComplete {
        Set-Status 'Otimização completa / Optimization complete'
    }
})

$window.FindName('AdvancedPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    switch ($button.Tag) {
        'ProcessLasso' { Invoke-LinaToolIntegration -Tool 'ProcessLasso' }
        'NvidiaInspector' { Invoke-LinaToolIntegration -Tool 'NvidiaInspector' }
        'UnparkCPU' { Invoke-LinaToolIntegration -Tool 'UnparkCPU' }
        'ParkControl' { Invoke-LinaToolIntegration -Tool 'ParkControl' }
        'DiscordDebloat' {
            Invoke-LinaRunspace -Name 'DiscordDebloat' -ScriptBlock {
                param($simulation)
                Invoke-LinaDiscordDebloat -WhatIf:$simulation
            } -Arguments @($script:Simulation)
        }
    }
})

function Invoke-LinaToolIntegration {
    param([string]$Tool)
    $paths = @()
    $url = ''

    switch ($Tool) {
        'ProcessLasso' {
            $paths = @(
                "$env:ProgramFiles\Process Lasso\ProcessLasso.exe",
                "$env:ProgramFiles(x86)\Process Lasso\ProcessLasso.exe"
            )
            $url = 'https://bitsum.com/'
        }
        'NvidiaInspector' {
            $paths = @(
                "$env:ProgramFiles\NVIDIA Corporation\Profile Inspector\nvidiaProfileInspector.exe",
                "$env:USERPROFILE\Desktop\nvidiaProfileInspector.exe"
            )
            $url = 'https://github.com/Orbmu2k/nvidiaProfileInspector'
        }
        'UnparkCPU' {
            $paths = @(
                "$env:ProgramFiles\Unpark CPU\UnparkCPU.exe",
                "$env:ProgramFiles(x86)\Unpark CPU\UnparkCPU.exe"
            )
            $url = 'https://bitsum.com/'
        }
        'ParkControl' {
            $paths = @(
                "$env:ProgramFiles\ParkControl\ParkControl.exe",
                "$env:ProgramFiles(x86)\ParkControl\ParkControl.exe"
            )
            $url = 'https://bitsum.com/parkcontrol/'
        }
    }

    foreach ($path in $paths) {
        if (Test-Path $path) {
            Start-Process $path
            return
        }
    }

    if ($url) {
        Start-Process $url
    }
}

$window.FindName('DiscordButton').Add_Click({
    Start-Process 'https://discord.gg/CFw33ukueK'
})

$window.FindName('CloseButton').Add_Click({
    $window.Close()
})
$window.FindName('MinimizeButton').Add_Click({
    $window.WindowState = 'Minimized'
})

$window.ShowDialog() | Out-Null
$script:RunspacePool.Close()
$script:RunspacePool.Dispose()
