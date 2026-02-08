#requires -Version 5.1
$ErrorActionPreference = 'Stop'

# Encoding / UTF-8
chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

# Hide console window
Add-Type -Namespace Lina -Name Win32 -MemberDefinition @"
[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
"@
$console = [Lina.Win32]::GetConsoleWindow()
if ($console -ne [IntPtr]::Zero) { [Lina.Win32]::ShowWindow($console, 0) | Out-Null }

$Script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Script:LogPath = Join-Path $Script:AppRoot 'logs'
$Script:ModulesPath = Join-Path $Script:AppRoot 'modules'
$Script:AssetsPath = Join-Path $Script:AppRoot 'assets'
$Script:RunspacePool = [runspacefactory]::CreateRunspacePool(1, 4)
$Script:RunspacePool.Open()

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','WARN','ERROR')] [string]$Level = 'INFO'
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$timestamp][$Level] $Message"
    $logFile = Join-Path $Script:LogPath 'lina-optimizer.log'
    $line | Out-File -FilePath $logFile -Append
}

function Test-WhatIf {
    param([hashtable]$Options, [string]$Action)
    if ($Options -and $Options.WhatIf) {
        Write-Log -Message "Simulation / Simulação: $Action"
        return $true
    }
    return $false
}

function Invoke-Async {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$ArgumentList = @(),
        [scriptblock]$OnComplete
    )
    $ps = [powershell]::Create()
    $ps.RunspacePool = $Script:RunspacePool
    $null = $ps.AddScript($ScriptBlock).AddArgument($ArgumentList)
    $handle = $ps.BeginInvoke()
    Register-ObjectEvent -InputObject $handle -EventName Completed -Action {
        try {
            $result = $ps.EndInvoke($handle)
            if ($OnComplete) { & $OnComplete $result }
        } catch {
            Write-Log -Message "Async error: $($_.Exception.Message)" -Level ERROR
        } finally {
            $ps.Dispose()
        }
    } | Out-Null
}

function Show-Toast {
    param([string]$Message)
    $toast.Text = $Message
}

# Import modules
Get-ChildItem -Path $Script:ModulesPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Load XAML UI
[xml]$xaml = Get-Content -Path (Join-Path $Script:AppRoot 'ui.xaml')
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find controls
$toast = $window.FindName('ToastText')
$nav = $window.FindName('NavList')
$views = @{
    Dashboard = $window.FindName('DashboardView')
    Sistema = $window.FindName('SystemView')
    Jogos = $window.FindName('GamesView')
    Rede = $window.FindName('NetworkView')
    Debloat = $window.FindName('DebloatView')
    Kernel = $window.FindName('KernelView')
    Energia = $window.FindName('PowerView')
    Backup = $window.FindName('BackupView')
    Avancado = $window.FindName('AdvancedView')
    Discord = $window.FindName('DiscordView')
}

function Switch-View {
    param([string]$Name)
    $views.Keys | ForEach-Object { $views[$_].Visibility = 'Collapsed' }
    if ($views.ContainsKey($Name)) { $views[$Name].Visibility = 'Visible' }
}

$nav.Add_SelectionChanged({
    $selected = $nav.SelectedItem
    if ($selected -and $selected.Tag) { Switch-View -Name $selected.Tag }
})

# Dashboard detection
function Get-SystemSnapshot {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
    $ramGb = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $disk = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -First 1
    $bios = Get-CimInstance -ClassName Win32_BIOS | Select-Object -First 1
    $net = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "NetEnabled=true" | Select-Object -First 1
    return [pscustomobject]@{
        Windows = "$($os.Caption) ($($os.BuildNumber))"
        CPU = $cpu.Name
        GPU = $gpu.Name
        RAM = "$ramGb GB"
        SSD = "$($disk.Size/1GB -as [int]) GB"
        Network = $net.Name
        Account = "$env:UserDomain\\$env:UserName"
        BIOS = $bios.SMBIOSBIOSVersion
        Driver = $gpu.DriverVersion
    }
}

$dash = Get-SystemSnapshot
@('Windows','CPU','GPU','RAM','SSD','Network','Account','BIOS','Driver') | ForEach-Object {
    $label = $window.FindName("Dash$_")
    if ($label) { $label.Text = $dash.$_ }
}

# Buttons wiring
$window.FindName('ContinueButton').Add_Click({ Switch-View -Name 'Sistema' })
$window.FindName('JoinDiscord').Add_Click({ Start-Process 'https://discord.gg/CFw33ukueK' })

# System toggles
$window.FindName('ToggleTelemetry').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-Telemetry @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Telemetria / Telemetry aplicado.' } })
$window.FindName('ToggleAnimations').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-Animations @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Animações / Animations aplicado.' } })
$window.FindName('ToggleGameDVR').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-GameDVR @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'GameDVR / GameDVR aplicado.' } })
$window.FindName('ToggleIndexing').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-Indexing @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Indexação / Indexing aplicado.' } })
$window.FindName('ToggleEdgeBg').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-EdgeBackground @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Edge Background / Edge Background aplicado.' } })
$window.FindName('ToggleServices').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-UnusedServices @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Serviços / Services aplicado.' } })
$window.FindName('ToggleTimer').Add_Click({ Invoke-Async -ScriptBlock { param($args) Optimize-Timer @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Timer / Timer aplicado.' } })
$window.FindName('ToggleMSI').Add_Click({ Invoke-Async -ScriptBlock { param($args) Enable-MSIMode @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'MSI Mode / MSI Mode aplicado.' } })
$window.FindName('ToggleHPET').Add_Click({ Invoke-Async -ScriptBlock { param($args) Disable-HPET @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'HPET / HPET aplicado.' } })

# Game cards
Get-GameList | ForEach-Object {
    $panel = $window.FindName('GamesPanel')
    $card = New-Object System.Windows.Controls.Border
    $card.CornerRadius = 12
    $card.Margin = '8'
    $card.Padding = '12'
    $card.BorderBrush = '#3B6A94'
    $card.BorderThickness = '1'
    $card.Background = '#1C2B3A'
    $stack = New-Object System.Windows.Controls.StackPanel
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = "$($_.Name)"
    $title.Foreground = '#E6F2FF'
    $title.FontSize = 16
    $title.FontWeight = 'SemiBold'
    $status = New-Object System.Windows.Controls.TextBlock
    $status.Text = "Detectando... / Detecting..."
    $status.Foreground = '#9EC9FF'
    $status.Margin = '0,4,0,8'
    $btnRow = New-Object System.Windows.Controls.StackPanel
    $btnRow.Orientation = 'Horizontal'
    $opt = New-Object System.Windows.Controls.Button
    $opt.Content = 'Otimizar / Optimize'
    $opt.Margin = '0,0,8,0'
    $reset = New-Object System.Windows.Controls.Button
    $reset.Content = 'Resetar / Reset'
    $btnRow.Children.Add($opt) | Out-Null
    $btnRow.Children.Add($reset) | Out-Null
    $stack.Children.Add($title) | Out-Null
    $stack.Children.Add($status) | Out-Null
    $stack.Children.Add($btnRow) | Out-Null
    $card.Child = $stack
    $panel.Children.Add($card) | Out-Null

    $game = $_
    Invoke-Async -ScriptBlock { param($args) Test-GameInstalled @args } -ArgumentList @($game) -OnComplete {
        $installed = $args[0]
        $status.Text = if ($installed) { 'Instalado / Installed' } else { 'Não encontrado / Not found' }
    }

    $opt.Add_Click({
        Invoke-Async -ScriptBlock { param($args) Optimize-Game @args } -ArgumentList @($game, @{ WhatIf = $false }) -OnComplete {
            Show-Toast "$($game.Name) otimizado / optimized."
        }
    })
    $reset.Add_Click({
        Invoke-Async -ScriptBlock { param($args) Reset-Game @args } -ArgumentList @($game, @{ WhatIf = $false }) -OnComplete {
            Show-Toast "$($game.Name) resetado / reset."
        }
    })
}

# Network
$window.FindName('ApplyNetwork').Add_Click({ Invoke-Async -ScriptBlock { param($args) Apply-NetworkTweaks @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Rede / Network aplicado.' } })

# Debloat
$window.FindName('DebloatLight').Add_Click({ Invoke-Async -ScriptBlock { param($args) Invoke-Debloat -Level 'Light' @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Debloat leve / light aplicado.' } })
$window.FindName('DebloatMedium').Add_Click({ Invoke-Async -ScriptBlock { param($args) Invoke-Debloat -Level 'Medium' @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Debloat médio / medium aplicado.' } })
$window.FindName('DebloatNuclear').Add_Click({ Invoke-Async -ScriptBlock { param($args) Invoke-Debloat -Level 'Nuclear' @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Debloat nuclear / nuclear aplicado.' } })

# Kernel
$window.FindName('ApplyKernel').Add_Click({ Invoke-Async -ScriptBlock { param($args) Apply-KernelTweaks @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Kernel / Boot aplicado.' } })

# Power
$window.FindName('ApplyPower').Add_Click({ Invoke-Async -ScriptBlock { param($args) Apply-PowerPlan @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Energia / Power aplicado.' } })

# Backup
$window.FindName('CreateRestore').Add_Click({ Invoke-Async -ScriptBlock { param($args) New-RestorePoint @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Restore Point criado.' } })
$window.FindName('BackupRegistry').Add_Click({ Invoke-Async -ScriptBlock { param($args) Backup-Registry @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Registro / Registry backup.' } })
$window.FindName('BackupConfigs').Add_Click({ Invoke-Async -ScriptBlock { param($args) Backup-Configs @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Configs backup.' } })
$window.FindName('RestoreAll').Add_Click({ Invoke-Async -ScriptBlock { param($args) Restore-All @args } -ArgumentList @(@{ WhatIf = $false }) -OnComplete { Show-Toast 'Restore completo.' } })

Switch-View -Name 'Dashboard'
$nav.SelectedIndex = 0

$window.ShowDialog() | Out-Null
$Script:RunspacePool.Close()
$Script:RunspacePool.Dispose()
