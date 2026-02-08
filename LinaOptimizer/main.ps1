#requires -Version 5.1
chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:LogRoot = Join-Path $script:AppRoot 'logs'
if (-not (Test-Path $script:LogRoot)) {
    New-Item -Path $script:LogRoot -ItemType Directory | Out-Null
}

. (Join-Path $script:AppRoot 'modules/system.ps1')
. (Join-Path $script:AppRoot 'modules/games.ps1')
. (Join-Path $script:AppRoot 'modules/network.ps1')
. (Join-Path $script:AppRoot 'modules/power.ps1')
. (Join-Path $script:AppRoot 'modules/debloat.ps1')
. (Join-Path $script:AppRoot 'modules/kernel.ps1')
. (Join-Path $script:AppRoot 'modules/backup.ps1')

$script:Simulation = $false
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
    [void]$ps.AddScript($ScriptBlock).AddArgument($Arguments)

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

function Get-TextPair {
    param([string]$PT, [string]$EN)
    "$PT / $EN"
}

function Get-SystemInfoView {
    $info = Get-LinaSystemInfo
    @(
        [pscustomobject]@{ Label = Get-TextPair 'Windows' 'Windows'; Value = $info.Windows },
        [pscustomobject]@{ Label = Get-TextPair 'CPU' 'CPU'; Value = $info.CPU },
        [pscustomobject]@{ Label = Get-TextPair 'GPU' 'GPU'; Value = $info.GPU },
        [pscustomobject]@{ Label = Get-TextPair 'RAM' 'RAM'; Value = $info.RAM },
        [pscustomobject]@{ Label = Get-TextPair 'SSD' 'SSD'; Value = $info.SSD },
        [pscustomobject]@{ Label = Get-TextPair 'Rede' 'Network'; Value = $info.Network },
        [pscustomobject]@{ Label = Get-TextPair 'Conta' 'Account'; Value = $info.Account },
        [pscustomobject]@{ Label = Get-TextPair 'BIOS' 'BIOS'; Value = $info.BIOS },
        [pscustomobject]@{ Label = Get-TextPair 'Driver' 'Driver'; Value = $info.Driver }
    )
}

$viewModel = [pscustomobject]@{
    AppTitle = 'Lina Optimizer'
    Tagline = Get-TextPair 'Otimização extrema para Windows e jogos' 'Extreme optimization for Windows and games'
    SystemInfo = Get-SystemInfoView
    SystemTweaks = Get-LinaSystemTweaks
    NetworkTweaks = Get-LinaNetworkTweaks
    KernelTweaks = Get-LinaKernelTweaks
    GameList = Get-LinaGameProfiles
    DebloatModes = Get-LinaDebloatModes
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
[xml]$xaml = Get-Content -Path (Join-Path $script:AppRoot 'ui.xaml') -Raw
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$window.DataContext = $viewModel

$window.FindName('StatusText').Text = Get-TextPair 'Pronto' 'Ready'

function Set-Status {
    param([string]$Message)
    $window.Dispatcher.Invoke([action]{
        $window.FindName('StatusText').Text = $Message
    })
}

$window.Add_SourceInitialized({
    Set-Status (Get-TextPair 'Verificando permissões...' 'Checking permissions...')
    if (-not (Test-LinaAdmin)) {
        Set-Status (Get-TextPair 'Execute como Administrador' 'Run as Administrator')
    } else {
        Set-Status (Get-TextPair 'Admin OK' 'Admin OK')
    }
})

$window.FindName('ContinueButton').Add_Click({
    $window.FindName('MainTabs').SelectedIndex = 0
})

$window.FindName('SimToggle').Add_Checked({
    $script:Simulation = $true
    Set-Status (Get-TextPair 'Modo simulação ON' 'Simulation mode ON')
})
$window.FindName('SimToggle').Add_Unchecked({
    $script:Simulation = $false
    Set-Status (Get-TextPair 'Modo simulação OFF' 'Simulation mode OFF')
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
    $message = if ($isEnabled) { Get-TextPair "Aplicando $key" "Applying $key" } else { Get-TextPair "Revertendo $key" "Reverting $key" }
    Set-Status $message
    Invoke-LinaRunspace -Name $key -ScriptBlock {
        param($args)
        $k, $enabled, $simulation = $args
        Set-LinaSystemTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status (Get-TextPair 'Operação concluída' 'Operation completed')
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
    Set-Status (Get-TextPair "Rede: $key" "Network: $key")
    Invoke-LinaRunspace -Name "Network-$key" -ScriptBlock {
        param($args)
        $k, $enabled, $simulation = $args
        Set-LinaNetworkTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status (Get-TextPair 'Rede atualizada' 'Network updated')
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
    Set-Status (Get-TextPair "Kernel: $key" "Kernel: $key")
    Invoke-LinaRunspace -Name "Kernel-$key" -ScriptBlock {
        param($args)
        $k, $enabled, $simulation = $args
        Set-LinaKernelTweak -Key $k -Enabled:$enabled -WhatIf:$simulation
    } -Arguments @($key, $isEnabled, $script:Simulation) -OnComplete {
        Set-Status (Get-TextPair 'Kernel atualizado' 'Kernel updated')
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
        Set-Status (Get-TextPair "Otimizando $gameKey" "Optimizing $gameKey")
        Invoke-LinaRunspace -Name "Game-$gameKey-Optimize" -ScriptBlock {
            param($args)
            $k, $simulation = $args
            Invoke-LinaGameOptimization -GameKey $k -WhatIf:$simulation
        } -Arguments @($gameKey, $script:Simulation) -OnComplete {
            Set-Status (Get-TextPair 'Game otimizado' 'Game optimized')
        }
    }
    if ($action -eq 'Reset') {
        Set-Status (Get-TextPair "Resetando $gameKey" "Resetting $gameKey")
        Invoke-LinaRunspace -Name "Game-$gameKey-Reset" -ScriptBlock {
            param($args)
            $k, $simulation = $args
            Reset-LinaGameOptimization -GameKey $k -WhatIf:$simulation
        } -Arguments @($gameKey, $script:Simulation) -OnComplete {
            Set-Status (Get-TextPair 'Game resetado' 'Game reset')
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
        Set-Status (Get-TextPair "Debloat $mode" "Debloat $mode")
        Invoke-LinaRunspace -Name "Debloat-$mode" -ScriptBlock {
            param($args)
            $m, $simulation = $args
            Invoke-LinaDebloat -Mode $m -WhatIf:$simulation
        } -Arguments @($mode, $script:Simulation) -OnComplete {
            Set-Status (Get-TextPair 'Debloat concluído' 'Debloat completed')
        }
    }
})

$window.FindName('PowerPlanButton').Add_Click({
    Set-Status (Get-TextPair 'Criando plano de energia' 'Creating power plan')
    Invoke-LinaRunspace -Name 'PowerPlan' -ScriptBlock {
        param($args)
        $simulation = $args[0]
        New-LinaPowerPlan -WhatIf:$simulation
    } -Arguments @($script:Simulation) -OnComplete {
        Set-Status (Get-TextPair 'Plano aplicado' 'Plan applied')
    }
})

$window.FindName('BackupPanel').AddHandler([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent, [System.Windows.RoutedEventHandler]{
    $button = $_.OriginalSource
    if ($button -isnot [System.Windows.Controls.Button]) {
        return
    }
    switch ($button.Tag) {
        'RestorePoint' {
            Set-Status (Get-TextPair 'Criando restore point' 'Creating restore point')
            Invoke-LinaRunspace -Name 'RestorePoint' -ScriptBlock {
                param($args)
                $simulation = $args[0]
                New-LinaRestorePoint -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status (Get-TextPair 'Restore point criado' 'Restore point created')
            }
        }
        'BackupRegistry' {
            Set-Status (Get-TextPair 'Backup do registro' 'Registry backup')
            Invoke-LinaRunspace -Name 'BackupRegistry' -ScriptBlock {
                param($args)
                $simulation = $args[0]
                Backup-LinaRegistry -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status (Get-TextPair 'Backup concluído' 'Backup completed')
            }
        }
        'BackupConfigs' {
            Set-Status (Get-TextPair 'Backup configs' 'Backup configs')
            Invoke-LinaRunspace -Name 'BackupConfigs' -ScriptBlock {
                param($args)
                $simulation = $args[0]
                Backup-LinaGameConfigs -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status (Get-TextPair 'Backup concluído' 'Backup completed')
            }
        }
        'RestoreAll' {
            Set-Status (Get-TextPair 'Restaurando tudo' 'Restoring everything')
            Invoke-LinaRunspace -Name 'RestoreAll' -ScriptBlock {
                param($args)
                $simulation = $args[0]
                Restore-LinaAll -WhatIf:$simulation
            } -Arguments @($script:Simulation) -OnComplete {
                Set-Status (Get-TextPair 'Restauração finalizada' 'Restore finished')
            }
        }
    }
})

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
