function Get-LinaDashboardSummary {
    $alerts = @()
    $score = 100

    if (-not (Test-LinaAdmin)) {
        $alerts += 'Admin mode disabled / Modo admin desativado'
        $score -= 15
    }

    $updateService = Get-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
    if ($updateService -and $updateService.Status -eq 'Running') {
        $alerts += 'Windows Update ativo / Windows Update active'
        $score -= 5
    }

    $telemetry = (Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -ErrorAction SilentlyContinue).AllowTelemetry
    if ($telemetry -ne 0) {
        $alerts += 'Telemetria ativa / Telemetry enabled'
        $score -= 5
    }

    $score = [Math]::Max(0, $score)

    [pscustomobject]@{
        HealthScore = $score
        HealthMessage = if ($score -gt 80) { 'Sistema saudável / System healthy' } elseif ($score -gt 60) { 'Ajustes recomendados / Tweaks recommended' } else { 'Otimização crítica / Critical tuning' }
        Alerts = $alerts
    }
}

function Get-LinaSystemInfo {
    $os = $null
    $cpu = $null
    $gpu = $null
    $disks = @()
    $net = $null
    $bios = $null
    try { $os = Get-CimInstance Win32_OperatingSystem } catch { $os = Get-WmiObject Win32_OperatingSystem }
    try { $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1 } catch { $cpu = Get-WmiObject Win32_Processor | Select-Object -First 1 }
    try { $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1 } catch { $gpu = Get-WmiObject Win32_VideoController | Select-Object -First 1 }
    try { $disks = Get-CimInstance Win32_DiskDrive | Sort-Object Index } catch { $disks = Get-WmiObject Win32_DiskDrive | Sort-Object Index }
    try { $net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled } | Select-Object -First 1 } catch { $net = Get-WmiObject Win32_NetworkAdapter | Where-Object { $_.NetEnabled } | Select-Object -First 1 }
    try { $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1 } catch { $bios = Get-WmiObject Win32_BIOS | Select-Object -First 1 }

    $storage = @()
    $logical = @()
    try { $logical = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" } catch { $logical = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" }
    if ($logical) {
        $storage += $logical | ForEach-Object {
            $sizeGb = if ($_.Size) { '{0:N0}GB' -f ($_.Size / 1GB) } else { 'N/A' }
            $freeGb = if ($_.FreeSpace) { '{0:N0}GB' -f ($_.FreeSpace / 1GB) } else { 'N/A' }
            "$($_.DeviceID) $sizeGb (Livre $freeGb)"
        }
    }
    if (-not $storage -and $disks) {
        $storage += $disks | ForEach-Object {
            $sizeGb = if ($_.Size) { '{0:N0}GB' -f ($_.Size / 1GB) } else { 'N/A' }
            $media = if ($_.MediaType) { $_.MediaType } else { 'Disk' }
            "$($_.Model) [$media] ($sizeGb)"
        }
    }

    [pscustomobject]@{
        Windows = if ($os) { "$($os.Caption) $($os.Version)" } else { 'Não detectado / Not detected' }
        CPU = if ($cpu) { $cpu.Name } else { 'Não detectado / Not detected' }
        GPU = if ($gpu) { $gpu.Name } else { 'Não detectado / Not detected' }
        RAM = if ($os -and $os.TotalVisibleMemorySize) { "{0:N0} GB" -f ($os.TotalVisibleMemorySize / 1MB) } else { 'Não detectado / Not detected' }
        Storage = if ($storage -and $storage.Count -gt 0) { $storage -join ' | ' } else { 'Não detectado / Not detected' }
        Network = if ($net) { $net.Name } else { 'Não detectado / Not detected' }
        Account = if ($env:USERDOMAIN -and $env:USERNAME) { "$env:USERDOMAIN\$env:USERNAME" } else { $env:USERNAME }
        BIOS = if ($bios) { "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)" } else { 'Não detectado / Not detected' }
        Driver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).ReleaseId
    }
}

function Get-LinaSystemInfoList {
    param([string]$Language = 'pt-BR')
    $info = Get-LinaSystemInfo
    $labels = if ($Language -eq 'pt-BR') {
        @{
            Windows = 'Windows'
            CPU = 'CPU'
            GPU = 'GPU'
            RAM = 'RAM'
            Storage = 'Armazenamento'
            Network = 'Rede'
            Account = 'Conta'
            BIOS = 'BIOS'
            Driver = 'Driver'
        }
    } else {
        @{
            Windows = 'Windows'
            CPU = 'CPU'
            GPU = 'GPU'
            RAM = 'RAM'
            Storage = 'Storage'
            Network = 'Network'
            Account = 'Account'
            BIOS = 'BIOS'
            Driver = 'Driver'
        }
    }

    @(
        [pscustomobject]@{ Label = $labels.Windows; Value = $info.Windows },
        [pscustomobject]@{ Label = $labels.CPU; Value = $info.CPU },
        [pscustomobject]@{ Label = $labels.GPU; Value = $info.GPU },
        [pscustomobject]@{ Label = $labels.RAM; Value = $info.RAM },
        [pscustomobject]@{ Label = $labels.Storage; Value = $info.Storage },
        [pscustomobject]@{ Label = $labels.Network; Value = $info.Network },
        [pscustomobject]@{ Label = $labels.Account; Value = $info.Account },
        [pscustomobject]@{ Label = $labels.BIOS; Value = $info.BIOS },
        [pscustomobject]@{ Label = $labels.Driver; Value = $info.Driver }
    )
}

function Get-LinaSystemTweaks {
    param([string]$Language = 'pt-BR')
    $catalog = Get-LinaSystemTweakCatalog
    $catalog.GetEnumerator() | ForEach-Object {
        $item = $_.Value
        [pscustomobject]@{
            Key = $item.Key
            Title = if ($Language -eq 'pt-BR') { $item.TitlePT } else { $item.TitleEN }
            Description = if ($Language -eq 'pt-BR') { $item.DescriptionPT } else { $item.DescriptionEN }
            Category = if ($Language -eq 'pt-BR') { $item.CategoryPT } else { $item.CategoryEN }
            Risk = if ($Language -eq 'pt-BR') { $item.RiskPT } else { $item.RiskEN }
        }
    } | Sort-Object Title
}

function Get-LinaSystemTweakCatalog {
    $catalog = @{}
    function Add-LinaTweak {
        param(
            [string]$Key,
            [string]$CategoryPT,
            [string]$CategoryEN,
            [string]$RiskPT,
            [string]$RiskEN,
            [string]$TitlePT,
            [string]$TitleEN,
            [string]$DescriptionPT,
            [string]$DescriptionEN,
            [array]$Actions
        )
        $catalog[$Key] = [pscustomobject]@{
            Key = $Key
            CategoryPT = $CategoryPT
            CategoryEN = $CategoryEN
            RiskPT = $RiskPT
            RiskEN = $RiskEN
            TitlePT = $TitlePT
            TitleEN = $TitleEN
            DescriptionPT = $DescriptionPT
            DescriptionEN = $DescriptionEN
            Actions = $Actions
        }
    }

    $low = 'Baixo'
    $medium = 'Médio'
    $high = 'Alto'

    Add-LinaTweak 'DisableTelemetry' 'Telemetria' 'Telemetry' $medium 'Medium' 'Desativar Telemetria' 'Disable Telemetry' 'Reduz coleta de dados do sistema.' 'Reduce system data collection.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='AllowTelemetry'; Enable=0; Disable=3; ValueType='DWord' },
        @{ Type='Service'; Name='DiagTrack' }
    )
    Add-LinaTweak 'DisableErrorReporting' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar Error Reporting' 'Disable Error Reporting' 'Desliga envio automático de erros.' 'Disable automatic error reporting.' @(
        @{ Type='Service'; Name='WerSvc' }
    )
    Add-LinaTweak 'DisableCEIP' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar CEIP' 'Disable CEIP' 'Desativa programa de experiência.' 'Disable customer experience program.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Customer Experience Improvement Program\\Consolidator' }
    )
    Add-LinaTweak 'DisableCompatibilityAssistant' 'Sistema' 'System' $medium 'Medium' 'Desativar AppCompat' 'Disable AppCompat' 'Desliga assistente de compatibilidade.' 'Disable compatibility assistant.' @(
        @{ Type='Service'; Name='PcaSvc' }
    )
    Add-LinaTweak 'DisableAdvertisingId' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Advertising ID' 'Disable Advertising ID' 'Impede rastreio por apps.' 'Prevents app tracking.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTips' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Dicas' 'Disable Tips' 'Remove sugestões do Windows.' 'Remove Windows tips.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338389Enabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableContentDelivery' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Conteúdo Sugerido' 'Disable Suggested Content' 'Remove apps e conteúdo sugerido.' 'Remove suggested apps and content.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='ContentDeliveryAllowed'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableCortana' 'Search' 'Search' $medium 'Medium' 'Desativar Cortana' 'Disable Cortana' 'Desliga assistente Cortana.' 'Disable Cortana assistant.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowCortana'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSearchWeb' 'Search' 'Search' $low 'Low' 'Desativar Busca Web' 'Disable Web Search' 'Remove busca online no menu iniciar.' 'Disable web search from Start menu.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name='BingSearchEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSearchHighlights' 'Search' 'Search' $low 'Low' 'Desativar Search Highlights' 'Disable Search Highlights' 'Remove destaques de busca.' 'Remove search highlights.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name='IsDynamicSearchBoxEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableLocation' 'Privacidade' 'Privacy' $medium 'Medium' 'Desativar Localização' 'Disable Location' 'Impede acesso à localização.' 'Disable location access.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'; Name='DisableLocation'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableMicrophone' 'Privacidade' 'Privacy' $medium 'Medium' 'Desativar Microfone (apps)' 'Disable Microphone (apps)' 'Bloqueia apps UWP.' 'Block UWP apps.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name='LetAppsAccessMicrophone'; Enable=2; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableCamera' 'Privacidade' 'Privacy' $medium 'Medium' 'Desativar Câmera (apps)' 'Disable Camera (apps)' 'Bloqueia acesso à câmera.' 'Block camera access.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'; Name='LetAppsAccessCamera'; Enable=2; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableActivityHistory' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Histórico de Atividades' 'Disable Activity History' 'Desliga timeline do Windows.' 'Disable Windows timeline.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='PublishUserActivities'; Enable=0; Disable=1; ValueType='DWord' },
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='UploadUserActivities'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableFeedback' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Feedback' 'Disable Feedback' 'Impede solicitações de feedback.' 'Disable feedback prompts.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Siuf\Rules'; Name='NumberOfSIUFInPeriod'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTailoredExperiences' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Experiências Personalizadas' 'Disable Tailored Experiences' 'Desliga recomendações.' 'Disable tailored recommendations.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy'; Name='TailoredExperiencesWithDiagnosticDataEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableGameDVR' 'Jogos' 'Gaming' $medium 'Medium' 'Desativar Game DVR' 'Disable Game DVR' 'Desliga gravação em segundo plano.' 'Disable background recording.' @(
        @{ Type='Registry'; Path='HKCU:\System\GameConfigStore'; Name='GameDVR_Enabled'; Enable=0; Disable=1; ValueType='DWord' },
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name='AllowGameDVR'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableGameBar' 'Jogos' 'Gaming' $low 'Low' 'Desativar Game Bar' 'Disable Game Bar' 'Remove overlay do Xbox.' 'Disable Xbox overlay.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; Name='AllowGameDVR'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableXboxServices' 'Jogos' 'Gaming' $medium 'Medium' 'Desativar serviços Xbox' 'Disable Xbox services' 'Remove serviços de Xbox Live.' 'Disable Xbox Live services.' @(
        @{ Type='Service'; Name='XblAuthManager' },
        @{ Type='Service'; Name='XblGameSave' },
        @{ Type='Service'; Name='XboxNetApiSvc' }
    )
    Add-LinaTweak 'DisableBackgroundApps' 'Sistema' 'System' $low 'Low' 'Desativar Apps em Segundo Plano' 'Disable Background Apps' 'Bloqueia apps UWP em background.' 'Block UWP background apps.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications'; Name='GlobalUserDisabled'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableOneDrive' 'Sistema' 'System' $medium 'Medium' 'Desativar OneDrive' 'Disable OneDrive' 'Desliga sync do OneDrive.' 'Disable OneDrive sync.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; Name='DisableFileSyncNGSC'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableEdgePreload' 'Sistema' 'System' $low 'Low' 'Desativar Preload do Edge' 'Disable Edge Preload' 'Evita preload do Edge.' 'Disable Edge preload.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main'; Name='AllowPrelaunch'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableEdgeBackground' 'Sistema' 'System' $low 'Low' 'Desativar Edge em Background' 'Disable Edge Background' 'Evita Edge rodando em segundo plano.' 'Prevent Edge from running in background.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='BackgroundModeEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWidgets' 'Sistema' 'System' $low 'Low' 'Desativar Widgets' 'Disable Widgets' 'Remove painel de widgets.' 'Disable widgets panel.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name='AllowNewsAndInterests'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNewsFeeds' 'Sistema' 'System' $low 'Low' 'Desativar Notícias' 'Disable News Feeds' 'Remove notícias do taskbar.' 'Disable news feeds on taskbar.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds'; Name='ShellFeedsTaskbarViewMode'; Enable=2; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableChat' 'Sistema' 'System' $low 'Low' 'Desativar Chat' 'Disable Chat' 'Remove chat do taskbar.' 'Disable chat on taskbar.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarMn'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAnimations' 'UI' 'UI' $low 'Low' 'Desativar Animações' 'Disable Animations' 'Reduz animações do Windows.' 'Reduce Windows animations.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Desktop'; Name='MenuShowDelay'; Enable=0; Disable=400; ValueType='String' },
        @{ Type='Registry'; Path='HKCU:\Control Panel\Desktop\WindowMetrics'; Name='MinAnimate'; Enable='0'; Disable='1'; ValueType='String' }
    )
    Add-LinaTweak 'DisableTransparency' 'UI' 'UI' $low 'Low' 'Desativar Transparência' 'Disable Transparency' 'Remove efeitos de transparência.' 'Disable transparency effects.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='EnableTransparency'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAeroShake' 'UI' 'UI' $low 'Low' 'Desativar Aero Shake' 'Disable Aero Shake' 'Bloqueia minimizar ao sacudir.' 'Disable Aero Shake.' @(
        @{ Type='Registry'; Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='DisallowShaking'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableHibernation' 'Energia' 'Power' $medium 'Medium' 'Desativar Hibernação' 'Disable Hibernation' 'Libera espaço em disco.' 'Free disk space.' @(
        @{ Type='Command'; Enable='powercfg -h off'; Disable='powercfg -h on' }
    )
    Add-LinaTweak 'DisableFastStartup' 'Energia' 'Power' $medium 'Medium' 'Desativar Fast Startup' 'Disable Fast Startup' 'Desliga inicialização rápida.' 'Disable fast startup.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name='HiberbootEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSleep' 'Energia' 'Power' $medium 'Medium' 'Desativar Sleep' 'Disable Sleep' 'Remove suspensão automática.' 'Disable system sleep.' @(
        @{ Type='Command'; Enable='powercfg -x -standby-timeout-ac 0'; Disable='powercfg -x -standby-timeout-ac 30' }
    )
    Add-LinaTweak 'DisableUSBSelective' 'Energia' 'Power' $medium 'Medium' 'Desativar USB Selective Suspend' 'Disable USB Selective Suspend' 'Evita suspensão de USB.' 'Disable USB selective suspend.' @(
        @{ Type='Command'; Enable='powercfg -setacvalueindex scheme_current sub_usb USBSELECTIVE 0'; Disable='powercfg -setacvalueindex scheme_current sub_usb USBSELECTIVE 1' }
    )
    Add-LinaTweak 'DisablePCIeASPM' 'Energia' 'Power' $medium 'Medium' 'Desativar PCIe ASPM' 'Disable PCIe ASPM' 'Remove economia no PCIe.' 'Disable PCIe power saving.' @(
        @{ Type='Command'; Enable='powercfg -setacvalueindex scheme_current sub_pciexpress ASPM 0'; Disable='powercfg -setacvalueindex scheme_current sub_pciexpress ASPM 2' }
    )
    Add-LinaTweak 'DisableCoreParking' 'Kernel' 'Kernel' $high 'High' 'Desativar Core Parking' 'Disable Core Parking' 'Mantém núcleos ativos.' 'Keep CPU cores active.' @(
        @{ Type='Command'; Enable='powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100'; Disable='powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 10' }
    )
    Add-LinaTweak 'DisableSysMain' 'Serviços' 'Services' $medium 'Medium' 'Desativar SysMain' 'Disable SysMain' 'Desliga pré-carregamento.' 'Disable prefetch service.' @(
        @{ Type='Service'; Name='SysMain' }
    )
    Add-LinaTweak 'DisableWSearch' 'Serviços' 'Services' $medium 'Medium' 'Desativar Windows Search' 'Disable Windows Search' 'Desliga indexação.' 'Disable indexing service.' @(
        @{ Type='Service'; Name='WSearch' }
    )
    Add-LinaTweak 'DisablePrintSpooler' 'Serviços' 'Services' $medium 'Medium' 'Desativar Print Spooler' 'Disable Print Spooler' 'Remove spooler de impressão.' 'Disable print spooler.' @(
        @{ Type='Service'; Name='Spooler' }
    )
    Add-LinaTweak 'DisableFax' 'Serviços' 'Services' $low 'Low' 'Desativar Fax' 'Disable Fax' 'Remove serviço de fax.' 'Disable fax service.' @(
        @{ Type='Service'; Name='Fax' }
    )
    Add-LinaTweak 'DisableMaps' 'Serviços' 'Services' $low 'Low' 'Desativar MapsBroker' 'Disable MapsBroker' 'Desliga mapas offline.' 'Disable offline maps.' @(
        @{ Type='Service'; Name='MapsBroker' }
    )
    Add-LinaTweak 'DisableBluetooth' 'Serviços' 'Services' $medium 'Medium' 'Desativar Bluetooth' 'Disable Bluetooth' 'Desliga suporte Bluetooth.' 'Disable Bluetooth support.' @(
        @{ Type='Service'; Name='bthserv' }
    )
    Add-LinaTweak 'DisableRemoteRegistry' 'Serviços' 'Services' $medium 'Medium' 'Desativar Remote Registry' 'Disable Remote Registry' 'Bloqueia acesso remoto ao registro.' 'Disable remote registry.' @(
        @{ Type='Service'; Name='RemoteRegistry' }
    )
    Add-LinaTweak 'DisableRemoteDesktop' 'Segurança' 'Security' $medium 'Medium' 'Desativar Remote Desktop' 'Disable Remote Desktop' 'Desliga RDP.' 'Disable RDP.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'; Name='fDenyTSConnections'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableRemoteAssistance' 'Segurança' 'Security' $low 'Low' 'Desativar Remote Assistance' 'Disable Remote Assistance' 'Desativa assistência remota.' 'Disable remote assistance.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance'; Name='fAllowToGetHelp'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSMB1' 'Segurança' 'Security' $medium 'Medium' 'Desativar SMB1' 'Disable SMB1' 'Remove protocolo legado.' 'Disable legacy SMB1.' @(
        @{ Type='Command'; Enable='dism /online /disable-feature /featurename:SMB1Protocol /norestart'; Disable='dism /online /enable-feature /featurename:SMB1Protocol /norestart' }
    )
    Add-LinaTweak 'DisablePowerThrottling' 'Energia' 'Power' $medium 'Medium' 'Desativar Power Throttling' 'Disable Power Throttling' 'Mantém CPU em alta performance.' 'Keep CPU at high performance.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; Name='PowerThrottlingOff'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePrefetch' 'Sistema' 'System' $medium 'Medium' 'Desativar Prefetch' 'Disable Prefetch' 'Desliga prefetch de apps.' 'Disable application prefetch.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnablePrefetcher'; Enable=0; Disable=3; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSuperfetch' 'Sistema' 'System' $medium 'Medium' 'Desativar Superfetch' 'Disable Superfetch' 'Desliga prefetch avançado.' 'Disable superfetch.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnableSuperfetch'; Enable=0; Disable=3; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoMaintenance' 'Sistema' 'System' $low 'Low' 'Desativar Manutenção Automática' 'Disable Automatic Maintenance' 'Evita tarefas de manutenção.' 'Disable maintenance tasks.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance'; Name='MaintenanceDisabled'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDefenderRealtime' 'Segurança' 'Security' $high 'High' 'Desativar Defender Real-time' 'Disable Defender Real-time' 'Desliga proteção em tempo real.' 'Disable real-time protection.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection'; Name='DisableRealtimeMonitoring'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDefenderCloud' 'Segurança' 'Security' $medium 'Medium' 'Desativar Defender Cloud' 'Disable Defender Cloud' 'Desliga proteção baseada em nuvem.' 'Disable cloud-based protection.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet'; Name='SubmitSamplesConsent'; Enable=2; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSmartScreen' 'Segurança' 'Security' $medium 'Medium' 'Desativar SmartScreen' 'Disable SmartScreen' 'Desliga filtro SmartScreen.' 'Disable SmartScreen filter.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableSmartScreen'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsUpdate' 'Update' 'Update' $high 'High' 'Desativar Windows Update' 'Disable Windows Update' 'Desliga serviço de updates.' 'Disable Windows Update service.' @(
        @{ Type='Service'; Name='wuauserv' }
    )
    Add-LinaTweak 'DisableDeliveryOptimization' 'Update' 'Update' $medium 'Medium' 'Desativar Delivery Optimization' 'Disable Delivery Optimization' 'Remove P2P de updates.' 'Disable update P2P.' @(
        @{ Type='Service'; Name='DoSvc' }
    )
    Add-LinaTweak 'DisableDriverUpdates' 'Update' 'Update' $medium 'Medium' 'Desativar Driver Updates' 'Disable Driver Updates' 'Evita drivers automáticos.' 'Disable automatic driver updates.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'; Name='ExcludeWUDriversInQualityUpdate'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableUpdateSharing' 'Update' 'Update' $low 'Low' 'Desativar Compartilhamento Update' 'Disable Update Sharing' 'Desliga compartilhamento local.' 'Disable local update sharing.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'; Name='DODownloadMode'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableScheduledDefrag' 'Tasks' 'Tasks' $medium 'Medium' 'Desativar Defrag Agendado' 'Disable Scheduled Defrag' 'Desliga tarefa de otimização.' 'Disable scheduled defrag.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Defrag\\ScheduledDefrag' }
    )
    Add-LinaTweak 'DisableErrorReportingTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas de erro' 'Disable error tasks' 'Desliga tarefas do WER.' 'Disable WER tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Windows Error Reporting\\QueueReporting' }
    )
    Add-LinaTweak 'OptimizeWin32Priority' 'Kernel' 'Kernel' $medium 'Medium' 'Otimizar prioridade Win32' 'Optimize Win32 priority' 'Ajusta prioridade para apps.' 'Adjust Win32 priority.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl'; Name='Win32PrioritySeparation'; Enable=38; Disable=2; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableHPET' 'Kernel' 'Kernel' $high 'High' 'HPET Off' 'HPET Off' 'Desativa HPET no boot.' 'Disable HPET at boot.' @(
        @{ Type='Command'; Enable='bcdedit /set useplatformclock no'; Disable='bcdedit /deletevalue useplatformclock' }
    )
    Add-LinaTweak 'DisableDynamicTick' 'Kernel' 'Kernel' $high 'High' 'Dynamic Tick Off' 'Dynamic Tick Off' 'Desativa dynamic tick.' 'Disable dynamic tick.' @(
        @{ Type='Command'; Enable='bcdedit /set disabledynamictick yes'; Disable='bcdedit /deletevalue disabledynamictick' }
    )
    Add-LinaTweak 'DisableMitigations' 'Kernel' 'Kernel' $high 'High' 'Mitigations Off' 'Mitigations Off' 'Desativa mitigations de segurança.' 'Disable security mitigations.' @(
        @{ Type='Command'; Enable='bcdedit /set mitigations Off'; Disable='bcdedit /deletevalue mitigations' }
    )
    Add-LinaTweak 'DisableCET' 'Kernel' 'Kernel' $high 'High' 'CET Off' 'CET Off' 'Desativa Control-flow Enforcement.' 'Disable Control-flow Enforcement.' @(
        @{ Type='Command'; Enable='bcdedit /set disablecet 1'; Disable='bcdedit /deletevalue disablecet' }
    )
    Add-LinaTweak 'DisableDEP' 'Kernel' 'Kernel' $high 'High' 'DEP Off' 'DEP Off' 'Desativa DEP.' 'Disable DEP.' @(
        @{ Type='Command'; Enable='bcdedit /set nx AlwaysOff'; Disable='bcdedit /deletevalue nx' }
    )
    Add-LinaTweak 'DisableCFG' 'Kernel' 'Kernel' $high 'High' 'CFG Off' 'CFG Off' 'Desativa Control Flow Guard.' 'Disable Control Flow Guard.' @(
        @{ Type='Command'; Enable='powershell -Command "Set-ProcessMitigation -System -Disable CFG"'; Disable='powershell -Command "Set-ProcessMitigation -System -Enable CFG"' }
    )
    Add-LinaTweak 'EnableMSIMode' 'Drivers' 'Drivers' $high 'High' 'MSI Mode (Global)' 'MSI Mode (Global)' 'Ativa MSI em dispositivos compatíveis.' 'Enable MSI for compatible devices.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Pnp\PnpResources'; Name='EnableIRQ64'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableMouseAcceleration' 'Input' 'Input' $low 'Low' 'Desativar aceleração do mouse' 'Disable mouse acceleration' 'Remove "Enhance pointer precision".' 'Disable enhance pointer precision.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Mouse'; Name='MouseSpeed'; Enable=0; Disable=1; ValueType='String' },
        @{ Type='Registry'; Path='HKCU:\Control Panel\Mouse'; Name='MouseThreshold1'; Enable=0; Disable=6; ValueType='String' },
        @{ Type='Registry'; Path='HKCU:\Control Panel\Mouse'; Name='MouseThreshold2'; Enable=0; Disable=10; ValueType='String' }
    )
    Add-LinaTweak 'DisableStickyKeys' 'Input' 'Input' $low 'Low' 'Desativar Sticky Keys' 'Disable Sticky Keys' 'Evita ativação acidental.' 'Prevent accidental activation.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Accessibility\StickyKeys'; Name='Flags'; Enable='506'; Disable='510'; ValueType='String' }
    )
    Add-LinaTweak 'DisableFilterKeys' 'Input' 'Input' $low 'Low' 'Desativar Filter Keys' 'Disable Filter Keys' 'Desativa filtro de teclado.' 'Disable keyboard filter keys.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Accessibility\Keyboard Response'; Name='Flags'; Enable='122'; Disable='126'; ValueType='String' }
    )
    Add-LinaTweak 'DisableToggleKeys' 'Input' 'Input' $low 'Low' 'Desativar Toggle Keys' 'Disable Toggle Keys' 'Desativa alertas de teclado.' 'Disable toggle keys.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Accessibility\ToggleKeys'; Name='Flags'; Enable='58'; Disable='62'; ValueType='String' }
    )
    Add-LinaTweak 'DisableMouseTrails' 'UI' 'UI' $low 'Low' 'Desativar Mouse Trails' 'Disable Mouse Trails' 'Remove rastro do mouse.' 'Disable mouse trails.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Mouse'; Name='MouseTrails'; Enable=0; Disable=1; ValueType='String' }
    )
    Add-LinaTweak 'DisableExplorerRecent' 'UI' 'UI' $low 'Low' 'Desativar Recentes do Explorer' 'Disable Explorer recent files' 'Remove itens recentes no Explorer.' 'Disable recent items in Explorer.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='ShowRecent'; Enable=0; Disable=1; ValueType='DWord' },
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'; Name='ShowFrequent'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'ShowFileExtensions' 'UI' 'UI' $low 'Low' 'Mostrar extensões de arquivo' 'Show file extensions' 'Exibe extensões de arquivo.' 'Show file extensions.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='HideFileExt'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'ShowHiddenFiles' 'UI' 'UI' $low 'Low' 'Mostrar arquivos ocultos' 'Show hidden files' 'Exibe arquivos ocultos.' 'Show hidden files.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='Hidden'; Enable=1; Disable=2; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoPlay' 'Sistema' 'System' $low 'Low' 'Desativar AutoPlay' 'Disable AutoPlay' 'Evita execução automática.' 'Disable autoplay.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers'; Name='DisableAutoplay'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableUAC' 'Segurança' 'Security' $high 'High' 'Desativar UAC' 'Disable UAC' 'Desativa controle de conta.' 'Disable User Account Control.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name='EnableLUA'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNotifications' 'Sistema' 'System' $low 'Low' 'Desativar Notificações' 'Disable Notifications' 'Desliga notificações do Windows.' 'Disable Windows notifications.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications'; Name='ToastEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableActionCenter' 'Sistema' 'System' $low 'Low' 'Desativar Central de Ações' 'Disable Action Center' 'Remove Action Center.' 'Disable Action Center.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'; Name='DisableNotificationCenter'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableLockScreen' 'Sistema' 'System' $medium 'Medium' 'Desativar Lock Screen' 'Disable Lock Screen' 'Remove lock screen.' 'Disable lock screen.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name='NoLockScreen'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePowerShellTelemetry' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar Telemetria do PowerShell' 'Disable PowerShell telemetry' 'Desliga dados do PowerShell.' 'Disable PowerShell telemetry.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\PowerShell\3\PowerShellEngine'; Name='EnableConsoleHostTelemetry'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableStoreAutoUpdate' 'Sistema' 'System' $low 'Low' 'Desativar Auto-update da Store' 'Disable Store auto-update' 'Bloqueia updates da Microsoft Store.' 'Disable Microsoft Store auto updates.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'; Name='AutoDownload'; Enable=2; Disable=4; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableStickyNotes' 'Sistema' 'System' $low 'Low' 'Desativar Sticky Notes' 'Disable Sticky Notes' 'Desliga sincronização do Sticky Notes.' 'Disable Sticky Notes sync.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='AllowClipboardHistory'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableClipboardHistory' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Histórico da Área de Transferência' 'Disable Clipboard History' 'Remove histórico de clipboard.' 'Disable clipboard history.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='AllowClipboardHistory'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsInk' 'Input' 'Input' $low 'Low' 'Desativar Windows Ink' 'Disable Windows Ink' 'Remove serviços de caneta.' 'Disable pen services.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace'; Name='AllowWindowsInkWorkspace'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoUpdatesOffice' 'Update' 'Update' $low 'Low' 'Desativar updates do Office' 'Disable Office updates' 'Bloqueia updates automáticos do Office.' 'Disable Office auto updates.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate'; Name='enableautomaticupdates'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTelemetryTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas de telemetria' 'Disable telemetry tasks' 'Desliga tarefas compat/tel.' 'Disable telemetry tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Application Experience\\Microsoft Compatibility Appraiser' },
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater' }
    )
    Add-LinaTweak 'DisableScheduledMaintenance' 'Tasks' 'Tasks' $low 'Low' 'Desativar manutenção agendada' 'Disable scheduled maintenance' 'Desliga tarefas de manutenção.' 'Disable maintenance tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\TaskScheduler\\Maintenance Configurator' }
    )
    Add-LinaTweak 'DisableBluetoothTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas Bluetooth' 'Disable Bluetooth tasks' 'Remove tarefas do Bluetooth.' 'Disable Bluetooth tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Bluetooth\\UninstallDeviceTask' }
    )
    Add-LinaTweak 'DisableUpdateTasks' 'Tasks' 'Tasks' $medium 'Medium' 'Desativar tarefas de update' 'Disable update tasks' 'Desativa tarefas do Windows Update.' 'Disable Windows Update tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\WindowsUpdate\\Scheduled Start' }
    )
    Add-LinaTweak 'DisableTelemetryServices' 'Serviços' 'Services' $medium 'Medium' 'Desativar serviços de telemetria' 'Disable telemetry services' 'Desliga serviços de diagnóstico.' 'Disable diagnostic services.' @(
        @{ Type='Service'; Name='DiagTrack' },
        @{ Type='Service'; Name='dmwappushservice' }
    )
    Add-LinaTweak 'DisableWAP' 'Serviços' 'Services' $low 'Low' 'Desativar WAP Push' 'Disable WAP Push' 'Desliga serviço WAP.' 'Disable WAP push service.' @(
        @{ Type='Service'; Name='dmwappushservice' }
    )
    Add-LinaTweak 'DisableRetailDemo' 'Sistema' 'System' $low 'Low' 'Desativar Retail Demo' 'Disable Retail Demo' 'Remove modo demonstração.' 'Disable retail demo mode.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\RetailDemo'; Name='RetailDemo'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableLockScreenAds' 'Privacidade' 'Privacy' $low 'Low' 'Desativar anúncios da Lock Screen' 'Disable lock screen ads' 'Bloqueia sugestões.' 'Disable suggestions on lock screen.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='RotatingLockScreenOverlayEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWifiSense' 'Network' 'Network' $low 'Low' 'Desativar Wi-Fi Sense' 'Disable Wi-Fi Sense' 'Desliga Wi-Fi Sense.' 'Disable Wi-Fi Sense.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config'; Name='AutoConnectAllowedOEM'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePrinterSharing' 'Network' 'Network' $low 'Low' 'Desativar compartilhamento de impressora' 'Disable printer sharing' 'Remove compartilhamento.' 'Disable printer sharing.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Print'; Name='RpcAuthnLevelPrivacyEnabled'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNTFSLastAccess' 'Sistema' 'System' $low 'Low' 'Desativar NTFS Last Access' 'Disable NTFS Last Access' 'Reduz escrita em disco.' 'Reduce disk writes.' @(
        @{ Type='Command'; Enable='fsutil behavior set disablelastaccess 1'; Disable='fsutil behavior set disablelastaccess 0' }
    )
    Add-LinaTweak 'EnableLargeSystemCache' 'Memória' 'Memory' $medium 'Medium' 'Ativar Large System Cache' 'Enable Large System Cache' 'Melhora cache do sistema.' 'Improve system caching.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'; Name='LargeSystemCache'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableMemoryCompression' 'Memória' 'Memory' $medium 'Medium' 'Desativar Memory Compression' 'Disable Memory Compression' 'Remove compressão de memória.' 'Disable memory compression.' @(
        @{ Type='Command'; Enable='powershell -Command "Disable-MMAgent -MemoryCompression"'; Disable='powershell -Command "Enable-MMAgent -MemoryCompression"' }
    )
    Add-LinaTweak 'DisablePrefetchTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas Prefetch' 'Disable Prefetch tasks' 'Desliga tarefas de prefetch.' 'Disable prefetch tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Maintenance\\WinSAT' }
    )
    Add-LinaTweak 'DisableWindowsInkWorkspace' 'Input' 'Input' $low 'Low' 'Desativar Ink Workspace' 'Disable Ink Workspace' 'Desliga workspace de caneta.' 'Disable ink workspace.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\WindowsInkWorkspace'; Name='AllowSuggestedAppsInWindowsInkWorkspace'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoRestartUpdates' 'Update' 'Update' $medium 'Medium' 'Desativar reinício automático' 'Disable auto restart' 'Evita restart após updates.' 'Prevent automatic restart after updates.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'; Name='NoAutoRebootWithLoggedOnUsers'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDriveIndexing' 'Sistema' 'System' $low 'Low' 'Desativar indexação de disco' 'Disable drive indexing' 'Remove indexação de disco.' 'Disable disk indexing.' @(
        @{ Type='Command'; Enable='attrib +I "C:\\" /S /D'; Disable='attrib -I "C:\\" /S /D' }
    )
    Add-LinaTweak 'DisableDwmEffects' 'UI' 'UI' $low 'Low' 'Desativar efeitos DWM' 'Disable DWM effects' 'Reduz efeitos do DWM.' 'Reduce DWM effects.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name='EnableAeroPeek'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDwmAnimations' 'UI' 'UI' $low 'Low' 'Desativar animações do DWM' 'Disable DWM animations' 'Desliga animações do DWM.' 'Disable DWM animations.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\DWM'; Name='AlwaysHibernateThumbnails'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSysTrayAnimations' 'UI' 'UI' $low 'Low' 'Desativar animações do tray' 'Disable tray animations' 'Remove animação do tray.' 'Disable tray animation.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Desktop'; Name='UserPreferencesMask'; Enable=90; Disable=158; ValueType='Binary' }
    )
    Add-LinaTweak 'DisableAutoRun' 'Segurança' 'Security' $low 'Low' 'Desativar AutoRun' 'Disable AutoRun' 'Desliga AutoRun em mídias.' 'Disable AutoRun on media.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name='NoDriveTypeAutoRun'; Enable=255; Disable=145; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsTips' 'Sistema' 'System' $low 'Low' 'Desativar sugestões do Windows' 'Disable Windows tips' 'Remove dicas e sugestões.' 'Disable tips and suggestions.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338389Enabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDiagTrackTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas de diagnóstico' 'Disable diagnostic tasks' 'Desliga tarefas de telemetria.' 'Disable telemetry tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Autochk\\Proxy' },
        @{ Type='Task'; Name='\\Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticDataCollector' }
    )
    Add-LinaTweak 'DisableSystemRestore' 'Sistema' 'System' $high 'High' 'Desativar System Restore' 'Disable System Restore' 'Desliga restauração do sistema.' 'Disable system restore.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore'; Name='DisableSR'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsDefender' 'Segurança' 'Security' $high 'High' 'Desativar Windows Defender' 'Disable Windows Defender' 'Desliga o Defender.' 'Disable Windows Defender.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'; Name='DisableAntiSpyware'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWinUpdateMedic' 'Update' 'Update' $high 'High' 'Desativar Update Medic' 'Disable Update Medic' 'Desativa serviço de reparo do update.' 'Disable update medic service.' @(
        @{ Type='Service'; Name='WaaSMedicSvc' }
    )
    Add-LinaTweak 'DisableDriverTelemetry' 'Drivers' 'Drivers' $medium 'Medium' 'Desativar telemetria de drivers' 'Disable driver telemetry' 'Desliga coleta de drivers.' 'Disable driver telemetry.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata'; Name='PreventDeviceMetadataFromNetwork'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableInputTelemetry' 'Input' 'Input' $low 'Low' 'Desativar telemetria de input' 'Disable input telemetry' 'Desliga feedback de digitação.' 'Disable typing feedback telemetry.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Input\Settings'; Name='EnableTypingInsights'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableMapUpdates' 'Sistema' 'System' $low 'Low' 'Desativar updates de mapas' 'Disable map updates' 'Desliga atualização de mapas offline.' 'Disable offline map updates.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\Maps'; Name='AutoUpdateEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTipsNotifications' 'Sistema' 'System' $low 'Low' 'Desativar notificações de dicas' 'Disable tips notifications' 'Remove notificações de dicas.' 'Disable tips notifications.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications'; Name='NoToastApplicationNotification'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsInkSync' 'Input' 'Input' $low 'Low' 'Desativar sync Ink' 'Disable Ink sync' 'Desliga sincronização de tinta.' 'Disable ink sync.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PenWorkspace'; Name='PenWorkspaceAppSuggestionsEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAppPrelaunch' 'Sistema' 'System' $low 'Low' 'Desativar App Prelaunch' 'Disable app prelaunch' 'Evita prelaunch de apps.' 'Disable app prelaunch.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx'; Name='AllowPrelaunch'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableStorageSense' 'Sistema' 'System' $low 'Low' 'Desativar Storage Sense' 'Disable Storage Sense' 'Desativa limpeza automática.' 'Disable automatic cleanup.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'; Name='01'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDeliveryOptimizationTasks' 'Tasks' 'Tasks' $low 'Low' 'Desativar tarefas Delivery Optimization' 'Disable Delivery Optimization tasks' 'Desliga tarefas de DO.' 'Disable DO tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\DeliveryOptimization\\Maintenance' }
    )
    Add-LinaTweak 'DisableWindowsSearchIndexer' 'Serviços' 'Services' $medium 'Medium' 'Desativar Indexer' 'Disable Indexer' 'Desativa serviço de indexação.' 'Disable indexing service.' @(
        @{ Type='Service'; Name='WSearch' }
    )
    Add-LinaTweak 'DisableDiagnosticsTracking' 'Serviços' 'Services' $medium 'Medium' 'Desativar Diagnostics Tracking' 'Disable Diagnostics Tracking' 'Desliga serviço de diagnósticos.' 'Disable diagnostics tracking.' @(
        @{ Type='Service'; Name='DiagTrack' }
    )
    Add-LinaTweak 'DisableWindowsErrorReportingService' 'Serviços' 'Services' $low 'Low' 'Desativar WER Service' 'Disable WER Service' 'Desliga serviço de erros.' 'Disable error reporting service.' @(
        @{ Type='Service'; Name='WerSvc' }
    )
    Add-LinaTweak 'DisableTabletService' 'Serviços' 'Services' $low 'Low' 'Desativar Tablet Service' 'Disable Tablet Service' 'Desliga serviços de toque.' 'Disable touch services.' @(
        @{ Type='Service'; Name='TabletInputService' }
    )
    Add-LinaTweak 'DisableBiometrics' 'Serviços' 'Services' $medium 'Medium' 'Desativar Biometrics' 'Disable Biometrics' 'Desliga biometria.' 'Disable biometrics.' @(
        @{ Type='Service'; Name='WbioSrvc' }
    )
    Add-LinaTweak 'DisableDiagTrackRunner' 'Tasks' 'Tasks' $low 'Low' 'Desativar Autochk/Proxy' 'Disable Autochk/Proxy' 'Desliga tarefas Autochk.' 'Disable Autochk tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Autochk\\Proxy' }
    )
    Add-LinaTweak 'DisableScheduledDiagnostics' 'Tasks' 'Tasks' $low 'Low' 'Desativar diagnóstico agendado' 'Disable scheduled diagnostics' 'Desliga diagnósticos agendados.' 'Disable scheduled diagnostics.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Diagnosis\\Scheduled' }
    )
    Add-LinaTweak 'DisableDiskDiagnostic' 'Tasks' 'Tasks' $low 'Low' 'Desativar Disk Diagnostic' 'Disable Disk Diagnostic' 'Remove diagnóstico de disco.' 'Disable disk diagnostic.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticResolver' }
    )
    Add-LinaTweak 'DisableEdgeMetrics' 'Sistema' 'System' $low 'Low' 'Desativar Edge Metrics' 'Disable Edge Metrics' 'Desativa métricas do Edge.' 'Disable Edge metrics.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Edge'; Name='MetricsReportingEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSearchIndexerBackoff' 'Search' 'Search' $low 'Low' 'Desativar backoff do indexer' 'Disable indexer backoff' 'Ajusta backoff do indexer.' 'Adjust indexer backoff.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\WSearch\Parameters'; Name='BackOffHours'; Enable=0; Disable=12; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTaskbarSearchBox' 'Search' 'Search' $low 'Low' 'Desativar SearchBox no Taskbar' 'Disable taskbar search box' 'Remove busca do taskbar.' 'Disable taskbar search box.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; Name='SearchboxTaskbarMode'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSearchHistory' 'Search' 'Search' $low 'Low' 'Desativar histórico de busca' 'Disable search history' 'Desliga histórico de busca.' 'Disable search history.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name='IsDeviceSearchHistoryEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableClipboardCloud' 'Privacidade' 'Privacy' $low 'Low' 'Desativar clipboard em nuvem' 'Disable clipboard cloud' 'Desliga sync do clipboard.' 'Disable clipboard sync.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='AllowCrossDeviceClipboard'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableActivityFeed' 'Privacidade' 'Privacy' $low 'Low' 'Desativar Activity Feed' 'Disable Activity Feed' 'Desliga feed de atividade.' 'Disable activity feed.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableActivityFeed'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTelemetryProxy' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar telemetria via proxy' 'Disable telemetry via proxy' 'Desliga comunicação adicional.' 'Disable extra telemetry communication.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; Name='DisableTelemetryOptInSettingsUx'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableUpdateP2P' 'Update' 'Update' $low 'Low' 'Desativar Update P2P' 'Disable Update P2P' 'Desliga P2P de updates.' 'Disable updates P2P.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config'; Name='DODownloadMode'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDiagTrackAutologger' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar AutoLogger DiagTrack' 'Disable DiagTrack AutoLogger' 'Desliga autologger.' 'Disable autologger.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Diagtrack-Listener'; Name='Start'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableKernelTrace' 'Kernel' 'Kernel' $medium 'Medium' 'Desativar Kernel Trace' 'Disable Kernel Trace' 'Reduz logs do kernel.' 'Reduce kernel logs.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\KernelTraceControl'; Name='Start'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAudioEnhancements' 'Drivers' 'Drivers' $low 'Low' 'Desativar aprimoramentos de áudio' 'Disable audio enhancements' 'Remove efeitos de áudio.' 'Disable audio enhancements.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'; Name='DisableEnhancements'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableUsbPowerSaving' 'Energia' 'Power' $medium 'Medium' 'Desativar economia USB' 'Disable USB power saving' 'Mantém USB ativo.' 'Keep USB active.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\USB'; Name='DisableSelectiveSuspend'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNvTelemetry' 'Drivers' 'Drivers' $medium 'Medium' 'Desativar NVIDIA Telemetry' 'Disable NVIDIA Telemetry' 'Desliga telemetria NVIDIA.' 'Disable NVIDIA telemetry.' @(
        @{ Type='Service'; Name='NvTelemetryContainer' }
    )
    Add-LinaTweak 'DisableAMDTelemetry' 'Drivers' 'Drivers' $medium 'Medium' 'Desativar AMD Telemetry' 'Disable AMD Telemetry' 'Desliga telemetria AMD.' 'Disable AMD telemetry.' @(
        @{ Type='Service'; Name='AMD External Events Utility' }
    )
    Add-LinaTweak 'DisableStoreBackground' 'Sistema' 'System' $low 'Low' 'Desativar Store em background' 'Disable Store background' 'Remove execução em background.' 'Disable background execution.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\WindowsStore'; Name='DisableStoreApps'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableShellExperienceHost' 'Sistema' 'System' $high 'High' 'Desativar Shell Experience Host' 'Disable Shell Experience Host' 'Desliga host da shell.' 'Disable shell experience host.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableShellExperienceHost'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsSpotlight' 'Sistema' 'System' $low 'Low' 'Desativar Windows Spotlight' 'Disable Windows Spotlight' 'Remove Spotlight da lock screen.' 'Disable Spotlight on lock screen.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='RotatingLockScreenEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTimelineSync' 'Privacidade' 'Privacy' $low 'Low' 'Desativar sincronização de Timeline' 'Disable Timeline sync' 'Desativa sincronização de atividades.' 'Disable activity sync.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'; Name='EnableActivityFeed'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableGameMode' 'Jogos' 'Gaming' $low 'Low' 'Desativar Game Mode' 'Disable Game Mode' 'Desliga Game Mode.' 'Disable Game Mode.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\GameBar'; Name='AllowAutoGameMode'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableFullscreenOptimizations' 'Jogos' 'Gaming' $low 'Low' 'Desativar Fullscreen Optimizations' 'Disable Fullscreen Optimizations' 'Desativa otimizações de tela cheia.' 'Disable fullscreen optimizations.' @(
        @{ Type='Registry'; Path='HKCU:\System\GameConfigStore'; Name='GameDVR_FSEBehaviorMode'; Enable=2; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNetworkThrottling' 'Network' 'Network' $low 'Low' 'Desativar Network Throttling' 'Disable Network Throttling' 'Remove throttle de rede.' 'Disable network throttling.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='NetworkThrottlingIndex'; Enable=4294967295; Disable=10; ValueType='DWord' }
    )
    Add-LinaTweak 'SetSystemResponsiveness' 'Network' 'Network' $low 'Low' 'Otimizar System Responsiveness' 'Optimize System Responsiveness' 'Ajusta responsividade multimídia.' 'Adjust multimedia responsiveness.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'; Name='SystemResponsiveness'; Enable=0; Disable=20; ValueType='DWord' }
    )
    Add-LinaTweak 'EnableGameScheduling' 'Jogos' 'Gaming' $low 'Low' 'Otimizar Scheduler para jogos' 'Optimize scheduler for games' 'Ajusta perfis multimídia.' 'Adjust multimedia profiles.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Name='Priority'; Enable=6; Disable=2; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePrefetchService' 'Serviços' 'Services' $medium 'Medium' 'Desativar serviço Prefetch' 'Disable Prefetch service' 'Desliga serviço relacionado.' 'Disable related service.' @(
        @{ Type='Service'; Name='SysMain' }
    )
    Add-LinaTweak 'DisableSecurityCenter' 'Segurança' 'Security' $high 'High' 'Desativar Security Center' 'Disable Security Center' 'Desativa notificações de segurança.' 'Disable security center notifications.' @(
        @{ Type='Service'; Name='SecurityHealthService' }
    )
    Add-LinaTweak 'DisableWindowsSearchUI' 'Search' 'Search' $low 'Low' 'Desativar Search UI' 'Disable Search UI' 'Desliga Search UI host.' 'Disable Search UI host.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; Name='AllowSearchToUseLocation'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableDriverPowerSaving' 'Drivers' 'Drivers' $medium 'Medium' 'Desativar economia de drivers' 'Disable driver power saving' 'Evita economia agressiva.' 'Disable aggressive power saving.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Power'; Name='HiberbootEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAudioExclusiveMode' 'Drivers' 'Drivers' $low 'Low' 'Desativar Exclusive Mode de áudio' 'Disable audio exclusive mode' 'Remove exclusividade de áudio.' 'Disable audio exclusive mode.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'; Name='DeviceFormat'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsDefenderTasks' 'Tasks' 'Tasks' $medium 'Medium' 'Desativar tarefas do Defender' 'Disable Defender tasks' 'Desliga tarefas agendadas do Defender.' 'Disable Defender scheduled tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\Windows Defender\\Windows Defender Scheduled Scan' }
    )
    Add-LinaTweak 'DisableWindowsUpdateTasks' 'Tasks' 'Tasks' $medium 'Medium' 'Desativar tarefas do Windows Update' 'Disable Windows Update tasks' 'Remove tarefas automáticas.' 'Disable automatic update tasks.' @(
        @{ Type='Task'; Name='\\Microsoft\\Windows\\WindowsUpdate\\Automatic App Update' }
    )
    Add-LinaTweak 'DisableTelemetryAppCompat' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar AppCompat Telemetry' 'Disable AppCompat Telemetry' 'Desliga telemetria do AppCompat.' 'Disable AppCompat telemetry.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; Name='AITEnable'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWindowsErrorQueue' 'Telemetria' 'Telemetry' $low 'Low' 'Desativar fila de erro' 'Disable error queue' 'Desativa fila de erros.' 'Disable error queue.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; Name='Disabled'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableWifiAutoConfig' 'Network' 'Network' $medium 'Medium' 'Desativar WLAN AutoConfig' 'Disable WLAN AutoConfig' 'Desliga serviço Wi-Fi automático.' 'Disable WLAN auto config.' @(
        @{ Type='Service'; Name='WlanSvc' }
    )
    Add-LinaTweak 'DisableIPHelper' 'Network' 'Network' $low 'Low' 'Desativar IP Helper' 'Disable IP Helper' 'Desliga IP Helper.' 'Disable IP Helper service.' @(
        @{ Type='Service'; Name='iphlpsvc' }
    )
    Add-LinaTweak 'DisableQoS' 'Network' 'Network' $low 'Low' 'Desativar QoS' 'Disable QoS' 'Remove QoS no Windows.' 'Disable QoS.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched'; Name='NonBestEffortLimit'; Enable=0; Disable=20; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableNagleAlgorithm' 'Network' 'Network' $low 'Low' 'Desativar Nagle (TCPNoDelay)' 'Disable Nagle (TCPNoDelay)' 'Reduz latência TCP.' 'Reduce TCP latency.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name='TcpNoDelay'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'EnableRSS' 'Network' 'Network' $low 'Low' 'Ativar RSS' 'Enable RSS' 'Ativa Receive Side Scaling.' 'Enable Receive Side Scaling.' @(
        @{ Type='Command'; Enable='netsh int tcp set global rss=enabled'; Disable='netsh int tcp set global rss=disabled' }
    )
    Add-LinaTweak 'EnableRSC' 'Network' 'Network' $low 'Low' 'Ativar RSC' 'Enable RSC' 'Ativa Receive Segment Coalescing.' 'Enable Receive Segment Coalescing.' @(
        @{ Type='Command'; Enable='netsh int tcp set global rsc=enabled'; Disable='netsh int tcp set global rsc=disabled' }
    )
    Add-LinaTweak 'DisableECN' 'Network' 'Network' $low 'Low' 'Desativar ECN' 'Disable ECN' 'Desliga Explicit Congestion Notification.' 'Disable ECN.' @(
        @{ Type='Command'; Enable='netsh int tcp set global ecncapability=disabled'; Disable='netsh int tcp set global ecncapability=enabled' }
    )
    Add-LinaTweak 'SetMTU1500' 'Network' 'Network' $low 'Low' 'Definir MTU 1500' 'Set MTU 1500' 'Ajusta MTU padrão.' 'Set standard MTU.' @(
        @{ Type='Command'; Enable='netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent'; Disable='netsh interface ipv4 set subinterface "Ethernet" mtu=1480 store=persistent' }
    )
    Add-LinaTweak 'DisableLargeSendOffload' 'Network' 'Network' $low 'Low' 'Desativar LSO' 'Disable LSO' 'Desliga Large Send Offload.' 'Disable Large Send Offload.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'; Name='DisableTaskOffload'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableIPv6' 'Network' 'Network' $medium 'Medium' 'Desativar IPv6' 'Disable IPv6' 'Desliga IPv6 no sistema.' 'Disable IPv6.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters'; Name='DisabledComponents'; Enable=255; Disable=0; ValueType='DWord' }
    )

    Add-LinaTweak 'DisableLiveTiles' 'UI' 'UI' $low 'Low' 'Desativar Live Tiles' 'Disable Live Tiles' 'Remove tiles animados.' 'Disable live tiles.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'; Name='NoTileApplicationNotification'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePeopleBar' 'UI' 'UI' $low 'Low' 'Desativar People Bar' 'Disable People Bar' 'Remove People Bar do taskbar.' 'Disable People Bar on taskbar.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People'; Name='PeopleBand'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableTaskView' 'UI' 'UI' $low 'Low' 'Desativar Task View' 'Disable Task View' 'Remove botão Task View.' 'Disable Task View button.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='ShowTaskViewButton'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableLockScreenCamera' 'Privacidade' 'Privacy' $low 'Low' 'Desativar câmera na Lock Screen' 'Disable lock screen camera' 'Bloqueia câmera na lock screen.' 'Disable lock screen camera.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name='NoLockScreenCamera'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableLockScreenSlideshow' 'Privacidade' 'Privacy' $low 'Low' 'Desativar slideshow na Lock Screen' 'Disable lock screen slideshow' 'Bloqueia slideshow na lock screen.' 'Disable lock screen slideshow.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization'; Name='NoLockScreenSlideshow'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoRestartSignOn' 'Sistema' 'System' $low 'Low' 'Desativar Auto Restart Sign-On' 'Disable Auto Restart Sign-On' 'Impede login após update.' 'Disable auto sign-in after updates.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'; Name='DisableAutomaticRestartSignOn'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableFontSmoothing' 'UI' 'UI' $low 'Low' 'Desativar Font Smoothing' 'Disable Font Smoothing' 'Desativa suavização de fonte.' 'Disable font smoothing.' @(
        @{ Type='Registry'; Path='HKCU:\Control Panel\Desktop'; Name='FontSmoothing'; Enable='0'; Disable='2'; ValueType='String' }
    )
    Add-LinaTweak 'DisableStartupDelay' 'Sistema' 'System' $low 'Low' 'Desativar Startup Delay' 'Disable Startup Delay' 'Remove delay de inicialização.' 'Disable startup delay.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize'; Name='StartupDelayInMSec'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoLoggerReadyBoot' 'Sistema' 'System' $low 'Low' 'Desativar ReadyBoot AutoLogger' 'Disable ReadyBoot AutoLogger' 'Desliga ReadyBoot autologger.' 'Disable ReadyBoot autologger.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot'; Name='Start'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisablePrefetchParameters' 'Sistema' 'System' $low 'Low' 'Desativar Prefetch Parameters' 'Disable Prefetch Parameters' 'Ajusta parâmetros de prefetch.' 'Disable prefetch parameters.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'; Name='EnableBootTrace'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoRunDrive' 'Segurança' 'Security' $low 'Low' 'Desativar AutoRun em drive' 'Disable AutoRun per drive' 'Desativa autorun por drive.' 'Disable autorun per drive.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name='NoAutorun'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableSearchHistoryCloud' 'Search' 'Search' $low 'Low' 'Desativar histórico cloud' 'Disable cloud search history' 'Desliga histórico cloud.' 'Disable cloud search history.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; Name='IsCloudSearchEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableStartupApps' 'Sistema' 'System' $medium 'Medium' 'Desativar Startup Apps' 'Disable Startup Apps' 'Bloqueia apps de inicialização.' 'Disable startup apps.' @(
        @{ Type='Registry'; Path='HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run'; Name='LinaOptimizer'; Enable=3; Disable=2; ValueType='Binary' }
    )
    Add-LinaTweak 'DisableStorageService' 'Serviços' 'Services' $medium 'Medium' 'Desativar Storage Service' 'Disable Storage Service' 'Desliga serviço de storage.' 'Disable storage service.' @(
        @{ Type='Service'; Name='StorSvc' }
    )
    Add-LinaTweak 'DisableDiagServiceHost' 'Serviços' 'Services' $medium 'Medium' 'Desativar Diagnostic Service Host' 'Disable Diagnostic Service Host' 'Desliga Diagnostic Service Host.' 'Disable diagnostic service host.' @(
        @{ Type='Service'; Name='WdiServiceHost' }
    )
    Add-LinaTweak 'DisableDiagSystemHost' 'Serviços' 'Services' $medium 'Medium' 'Desativar Diagnostic System Host' 'Disable Diagnostic System Host' 'Desliga Diagnostic System Host.' 'Disable diagnostic system host.' @(
        @{ Type='Service'; Name='WdiSystemHost' }
    )
    Add-LinaTweak 'DisableWindowsPushNotifications' 'Serviços' 'Services' $medium 'Medium' 'Desativar WpnService' 'Disable WpnService' 'Desativa notificações push.' 'Disable push notifications service.' @(
        @{ Type='Service'; Name='WpnService' }
    )
    Add-LinaTweak 'DisableThemesService' 'Serviços' 'Services' $high 'High' 'Desativar Themes' 'Disable Themes' 'Desativa temas visuais.' 'Disable visual themes.' @(
        @{ Type='Service'; Name='Themes' }
    )
    Add-LinaTweak 'DisableAudioEndpointBuilder' 'Serviços' 'Services' $high 'High' 'Desativar AudioEndpointBuilder' 'Disable AudioEndpointBuilder' 'Desliga serviço de áudio.' 'Disable audio endpoint builder.' @(
        @{ Type='Service'; Name='AudioEndpointBuilder' }
    )
    Add-LinaTweak 'DisableBluetoothUserService' 'Serviços' 'Services' $medium 'Medium' 'Desativar Bluetooth User Service' 'Disable Bluetooth User Service' 'Desliga serviço de Bluetooth.' 'Disable Bluetooth user service.' @(
        @{ Type='Service'; Name='BluetoothUserService' }
    )
    Add-LinaTweak 'DisableWindowsTime' 'Serviços' 'Services' $medium 'Medium' 'Desativar Windows Time' 'Disable Windows Time' 'Desliga sincronização de horário.' 'Disable time sync.' @(
        @{ Type='Service'; Name='W32Time' }
    )
    Add-LinaTweak 'DisableBluetoothAudio' 'Serviços' 'Services' $medium 'Medium' 'Desativar Bluetooth Audio' 'Disable Bluetooth Audio' 'Desliga serviços de áudio BT.' 'Disable Bluetooth audio services.' @(
        @{ Type='Service'; Name='BthA2dp' }
    )
    Add-LinaTweak 'DisableTaskbarWidgetsPolicy' 'UI' 'UI' $low 'Low' 'Desativar Widgets (Policy)' 'Disable Widgets (policy)' 'Desativa widgets via policy.' 'Disable widgets via policy.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Policies\Microsoft\Dsh'; Name='AllowNewsAndInterests'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoplayPolicy' 'Sistema' 'System' $low 'Low' 'Desativar Autoplay (Policy)' 'Disable Autoplay (policy)' 'Desativa autoplay via policy.' 'Disable autoplay via policy.' @(
        @{ Type='Registry'; Path='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; Name='NoAutoplayfornonVolume'; Enable=1; Disable=0; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableBatterySaver' 'Energia' 'Power' $low 'Low' 'Desativar Battery Saver' 'Disable Battery Saver' 'Desliga bateria inteligente.' 'Disable battery saver.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Power'; Name='EnergyEstimationEnabled'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableAutoRestartOnCrash' 'Sistema' 'System' $low 'Low' 'Desativar auto restart em crash' 'Disable auto restart on crash' 'Evita restart automático.' 'Disable automatic restart.' @(
        @{ Type='Registry'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl'; Name='AutoReboot'; Enable=0; Disable=1; ValueType='DWord' }
    )
    Add-LinaTweak 'DisableEventLogServices' 'Serviços' 'Services' $high 'High' 'Desativar Event Log' 'Disable Event Log' 'Desliga serviço de log.' 'Disable event log service.' @(
        @{ Type='Service'; Name='EventLog' }
    )
    Add-LinaTweak 'DisableEdgeUpdate' 'Serviços' 'Services' $low 'Low' 'Desativar Edge Update' 'Disable Edge Update' 'Desliga serviços do Edge Update.' 'Disable Edge Update services.' @(
        @{ Type='Service'; Name='edgeupdate' },
        @{ Type='Service'; Name='edgeupdatem' }
    )
    Add-LinaTweak 'DisableAppXSvc' 'Serviços' 'Services' $high 'High' 'Desativar AppX Service' 'Disable AppX Service' 'Desliga AppX Deployment.' 'Disable AppX deployment service.' @(
        @{ Type='Service'; Name='AppXSvc' }
    )

    return $catalog
}

function Test-LinaAdmin {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $current
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-LinaSystemTweak {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter()] [switch]$Enabled
    )

    $catalog = Get-LinaSystemTweakCatalog
    $tweak = $catalog[$Key]
    if (-not $tweak) {
        return
    }

    foreach ($action in $tweak.Actions) {
        switch ($action.Type) {
            'Registry' {
                if ($PSCmdlet.ShouldProcess($action.Path, $action.Name)) {
                    $value = if ($Enabled) { $action.Enable } else { $action.Disable }
                    New-Item -Path $action.Path -Force | Out-Null
                    Set-ItemProperty -Path $action.Path -Name $action.Name -Value $value -Type $action.ValueType -Force
                }
            }
            'Service' {
                if ($PSCmdlet.ShouldProcess($action.Name, 'Service')) {
                    if ($Enabled) {
                        Stop-Service -Name $action.Name -Force -ErrorAction SilentlyContinue
                        Set-Service -Name $action.Name -StartupType Disabled -ErrorAction SilentlyContinue
                    } else {
                        Set-Service -Name $action.Name -StartupType Manual -ErrorAction SilentlyContinue
                        Start-Service -Name $action.Name -ErrorAction SilentlyContinue
                    }
                }
            }
            'Task' {
                if ($PSCmdlet.ShouldProcess($action.Name, 'Task')) {
                    if ($Enabled) {
                        schtasks /Change /TN $action.Name /Disable | Out-Null
                    } else {
                        schtasks /Change /TN $action.Name /Enable | Out-Null
                    }
                }
            }
            'Command' {
                $cmd = if ($Enabled) { $action.Enable } else { $action.Disable }
                if ($cmd -and $PSCmdlet.ShouldProcess('Command', $cmd)) {
                    cmd /c $cmd | Out-Null
                }
            }
        }
    }
}
