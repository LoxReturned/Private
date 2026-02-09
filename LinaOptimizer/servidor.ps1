#requires -Version 5.1
chcp 65001 | Out-Null
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$script:AppRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$env:LINA_APPROOT = $script:AppRoot
$script:WebRoot = Join-Path $script:AppRoot 'web'
$script:LogRoot = Join-Path $script:AppRoot 'logs'
if (-not (Test-Path $script:LogRoot)) {
    New-Item -Path $script:LogRoot -ItemType Directory | Out-Null
}

. (Join-Path $script:AppRoot 'modules\system.ps1')
. (Join-Path $script:AppRoot 'modules\games.ps1')
. (Join-Path $script:AppRoot 'modules\network.ps1')
. (Join-Path $script:AppRoot 'modules\power.ps1')
. (Join-Path $script:AppRoot 'modules\debloat.ps1')
. (Join-Path $script:AppRoot 'modules\kernel.ps1')
. (Join-Path $script:AppRoot 'modules\backup.ps1')

$script:ServerLog = New-Object System.Collections.Concurrent.ConcurrentQueue[string]
$script:ServerPort = $null
$script:ServerPrefix = $null

function Add-ServerLog {
    param([string]$Message)
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $entry = "[$timestamp] $Message"
    $script:ServerLog.Enqueue($entry)
    $logFile = Join-Path $script:LogRoot 'lina-server.log'
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

function Get-ServerLog {
    return $script:ServerLog.ToArray()
}

function Send-Json {
    param($Response, $Object)
    $json = $Object | ConvertTo-Json -Depth 6
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $Response.ContentType = 'application/json; charset=utf-8'
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Send-File {
    param($Response, [string]$Path, [string]$ContentType)
    if (-not (Test-Path $Path)) {
        $Response.StatusCode = 404
        $Response.OutputStream.Close()
        return
    }
    $bytes = [IO.File]::ReadAllBytes($Path)
    $Response.ContentType = $ContentType
    $Response.ContentLength64 = $bytes.Length
    $Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $Response.OutputStream.Close()
}

function Start-LinaListener {
    param([int]$Port)
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://+:$Port/")
    try {
        $listener.Start()
        return [pscustomobject]@{ Listener = $listener; Port = $Port; Prefix = "http://+:$Port/"; Fallback = $false }
    } catch {
        $listener.Close()
        $listener = New-Object System.Net.HttpListener
        $listener.Prefixes.Add("http://localhost:$Port/")
        try {
            $listener.Start()
            return [pscustomobject]@{ Listener = $listener; Port = $Port; Prefix = "http://localhost:$Port/"; Fallback = $true }
        } catch {
            $listener.Close()
            throw
        }
    }
}

function Get-LinaRandomPort {
    param([int]$Start = 8700, [int]$End = 8999)
    $ports = $Start..$End | Sort-Object { Get-Random }
    $preferred = $env:LINA_PORT
    if ($preferred) {
        $ports = @([int]$preferred) + ($ports | Where-Object { $_ -ne [int]$preferred })
    }
    foreach ($port in $ports) {
        try {
            $result = Start-LinaListener -Port $port
            return $result
        } catch {
            continue
        }
    }
    throw "Nenhuma porta disponível no intervalo ${Start}-${End}."
}

function Get-LinaLocalizationLabels {
    param([string]$Language = 'pt-BR')
    switch ($Language) {
        'pt-BR' {
            return @{
                Risks = @{ Low = 'Baixo'; Medium = 'Médio'; High = 'Alto' }
                Categories = @{ Network = 'Rede'; Kernel = 'Kernel'; Debloat = 'Debloat' }
            }
        }
        'es-ES' {
            return @{
                Risks = @{ Low = 'Bajo'; Medium = 'Medio'; High = 'Alto' }
                Categories = @{ Network = 'Red'; Kernel = 'Kernel'; Debloat = 'Debloat' }
            }
        }
        'de-DE' {
            return @{
                Risks = @{ Low = 'Niedrig'; Medium = 'Mittel'; High = 'Hoch' }
                Categories = @{ Network = 'Netzwerk'; Kernel = 'Kernel'; Debloat = 'Debloat' }
            }
        }
        default {
            return @{
                Risks = @{ Low = 'Low'; Medium = 'Medium'; High = 'High' }
                Categories = @{ Network = 'Network'; Kernel = 'Kernel'; Debloat = 'Debloat' }
            }
        }
    }
}

function Get-LinaTweaksPayload {
    param([string]$Language = 'pt-BR')
    $labels = Get-LinaLocalizationLabels -Language $Language
    $system = Get-LinaSystemTweaks -Language $Language | ForEach-Object {
        $group = Get-LinaCategoryGroup -Category $_.Category -Key $_.Key
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $_.Category; group = $group; risk = $_.Risk; type = 'system' }
    }
    $network = Get-LinaNetworkTweaks -Language $Language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $labels.Categories.Network; group = 'internet'; risk = $labels.Risks.Medium; type = 'network' }
    }
    $kernel = Get-LinaKernelTweaks -Language $Language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $labels.Categories.Kernel; group = 'kernel'; risk = $labels.Risks.High; type = 'kernel' }
    }
    $debloat = Get-LinaDebloatModes -Language $Language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $labels.Categories.Debloat; group = 'debloat'; risk = $labels.Risks.High; type = 'debloat' }
    }
    $system + $network + $kernel + $debloat
}

function Get-LinaCategoryGroup {
    param([string]$Category, [string]$Key)
    $categoryValue = if ($Category) { $Category.ToLower() } else { '' }
    switch -Regex ($categoryValue) {
        'network|rede' { return 'internet' }
        'kernel' { return 'kernel' }
        'energia|power|cpu|scheduler|memory' { return 'cpu' }
        'drivers|gpu' { return 'gpu' }
        'system|sistema|ui|tasks|serviços|services|update|security|segurança' { return 'system' }
        default { return 'extra' }
    }
}

function Add-LinaDetailLog {
    param([string]$Key, [string]$Message)
    Add-ServerLog "Detalhe ${Key}: $Message"
}

function Add-LinaSystemActionLogs {
    param([string]$Key, [bool]$Enabled)
    $catalog = Get-LinaSystemTweakCatalog
    $tweak = $catalog[$Key]
    if (-not $tweak) {
        return
    }
    foreach ($action in $tweak.Actions) {
        switch ($action.Type) {
            'Registry' {
                $value = if ($Enabled) { $action.Enable } else { $action.Disable }
                Add-LinaDetailLog $Key "Registry: $($action.Path) -> $($action.Name) = $value ($($action.ValueType))"
            }
            'Service' {
                $state = if ($Enabled) { 'Disabled' } else { 'Manual' }
                Add-LinaDetailLog $Key "Serviço: $($action.Name) StartupType=$state"
            }
            'Task' {
                $state = if ($Enabled) { 'Disabled' } else { 'Enabled' }
                Add-LinaDetailLog $Key "Task: $($action.Name) = $state"
            }
            'Command' {
                $cmd = if ($Enabled) { $action.Enable } else { $action.Disable }
                Add-LinaDetailLog $Key "Comando: $cmd"
            }
        }
    }
}

function Add-LinaNetworkActionLogs {
    param([string]$Key, [bool]$Enabled)
    switch ($Key) {
        'TCPNoDelay' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\* TCPNoDelay = $value (DWord)"
        }
        'TcpAckFrequency' {
            $value = if ($Enabled) { 1 } else { 2 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters\\Interfaces\\* TcpAckFrequency = $value (DWord)"
        }
        'NetworkThrottle' {
            $value = if ($Enabled) { '0xffffffff' } else { 10 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Multimedia\\SystemProfile NetworkThrottlingIndex = $value (DWord)"
        }
        'QoSDisable' {
            $value = if ($Enabled) { 0 } else { 20 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\Psched NonBestEffortLimit = $value (DWord)"
        }
        'InterruptModeration' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters EnableRSS = $value (DWord)"
        }
        'RSS' {
            $cmd = if ($Enabled) { 'netsh int tcp set global rss=enabled' } else { 'netsh int tcp set global rss=disabled' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'RSC' {
            $cmd = if ($Enabled) { 'netsh int tcp set global rsc=enabled' } else { 'netsh int tcp set global rsc=disabled' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'ECN' {
            $cmd = if ($Enabled) { 'netsh int tcp set global ecncapability=disabled' } else { 'netsh int tcp set global ecncapability=enabled' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'Offload' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Services\\Tcpip\\Parameters DisableTaskOffload = $value (DWord)"
        }
        'MTU1500' {
            $cmd = if ($Enabled) { 'netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent' } else { 'netsh interface ipv4 set subinterface "Ethernet" mtu=1480 store=persistent' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'Buffers' {
            $cmd = if ($Enabled) { 'netsh int tcp set global autotuninglevel=normal' } else { 'netsh int tcp set global autotuninglevel=highlyrestricted' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
    }
}

function Add-LinaKernelActionLogs {
    param([string]$Key, [bool]$Enabled)
    switch ($Key) {
        'HPETOff' {
            $cmd = if ($Enabled) { 'bcdedit /set useplatformclock no' } else { 'bcdedit /deletevalue useplatformclock' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'DynamicTickOff' {
            $cmd = if ($Enabled) { 'bcdedit /set disabledynamictick yes' } else { 'bcdedit /deletevalue disabledynamictick' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'MitigationsOff' {
            $cmd = if ($Enabled) { 'bcdedit /set mitigations Off' } else { 'bcdedit /deletevalue mitigations' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'CETOff' {
            $cmd = if ($Enabled) { 'bcdedit /set disablecet 1' } else { 'bcdedit /deletevalue disablecet' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'DEPOff' {
            $cmd = if ($Enabled) { 'bcdedit /set nx AlwaysOff' } else { 'bcdedit /deletevalue nx' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'CFGOff' {
            $cmd = if ($Enabled) { 'powershell -Command "Set-ProcessMitigation -System -Disable CFG"' } else { 'powershell -Command "Set-ProcessMitigation -System -Enable CFG"' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'CoreParkingOff' {
            $cmd = if ($Enabled) { 'powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100' } else { 'powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 10' }
            Add-LinaDetailLog $Key "Comando: $cmd"
        }
        'InterruptAffinity' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Control\\PriorityControl IRQ8Priority = $value (DWord)"
        }
        'PowerThrottlingOff' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Power\\PowerThrottling PowerThrottlingOff = $value (DWord)"
        }
        'MSIMode' {
            $value = if ($Enabled) { 1 } else { 0 }
            Add-LinaDetailLog $Key "Registry: HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Pnp\\PnpResources EnableIRQ64 = $value (DWord)"
        }
    }
}

function Add-LinaDebloatActionLogs {
    param([string]$Key)
    $plan = Get-LinaDebloatPlan -Mode $Key
    foreach ($app in $plan.Apps) {
        Add-LinaDetailLog $Key "Appx: Remover $app"
    }
    foreach ($svc in $plan.Services) {
        Add-LinaDetailLog $Key "Serviço: $svc StartupType=Disabled"
    }
    foreach ($task in $plan.Tasks) {
        Add-LinaDetailLog $Key "Task: $task = Disabled"
    }
    foreach ($registry in $plan.Registry) {
        Add-LinaDetailLog $Key "Registry: $($registry.Path) -> $($registry.Name) = $($registry.Value) ($($registry.ValueType))"
    }
    foreach ($cmd in $plan.Commands) {
        Add-LinaDetailLog $Key "Comando: $cmd"
    }
}

$listenerResult = Get-LinaRandomPort
$listener = $listenerResult.Listener
$script:ServerPort = $listenerResult.Port
$script:ServerPrefix = $listenerResult.Prefix
if ($listenerResult.Fallback) {
    Add-ServerLog "Servidor iniciado apenas em http://localhost:$script:ServerPort/ (fallback)"
} else {
    Add-ServerLog "Servidor iniciado em http://localhost:$script:ServerPort/"
}
try {
    Start-Process "http://localhost:$script:ServerPort/"
} catch {
    Add-ServerLog "Falha ao abrir navegador: $_"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    $path = $request.Url.AbsolutePath

    try {
        switch -Regex ($request.Url.AbsolutePath) {
            '^/$' {
                Send-File -Response $response -Path (Join-Path $script:WebRoot 'index.html') -ContentType 'text/html; charset=utf-8'
            }
            '^/app.js$' {
                Send-File -Response $response -Path (Join-Path $script:WebRoot 'app.js') -ContentType 'application/javascript; charset=utf-8'
            }
            '^/api/hardware$' {
                try {
                    $info = Get-LinaSystemInfo
                    Send-Json -Response $response -Object $info
                } catch {
                    Send-Json -Response $response -Object @{
                        Windows = 'Não detectado / Not detected'
                        CPU = 'Não detectado / Not detected'
                        GPU = 'Não detectado / Not detected'
                        RAM = 'Não detectado / Not detected'
                        Storage = 'Não detectado / Not detected'
                        Network = 'Não detectado / Not detected'
                        Account = "$env:USERDOMAIN\$env:USERNAME"
                        BIOS = 'Não detectado / Not detected'
                        Driver = 'Não detectado / Not detected'
                        Error = $_.Exception.Message
                    }
                }
            }
            '^/api/tweaks$' {
                $langParam = $request.QueryString['lang']
                $langValue = if ([string]::IsNullOrWhiteSpace($langParam)) { 'pt-BR' } else { $langParam }
                Send-Json -Response $response -Object (Get-LinaTweaksPayload -Language $langValue)
            }
            '^/api/games$' {
                $langParam = $request.QueryString['lang']
                $langValue = if ([string]::IsNullOrWhiteSpace($langParam)) { 'pt-BR' } else { $langParam }
                $games = Get-LinaGameProfiles -Language $langValue | ForEach-Object {
                    [pscustomobject]@{ key = $_.Key; name = $_.Name; description = $_.Description; detectLabel = $_.DetectLabel }
                }
                Send-Json -Response $response -Object $games
            }
            '^/api/games/apply$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Set-LinaGameQuality -GameKey $data.gameKey -Quality $data.quality -WhatIf:$false
                Add-ServerLog "Aplicado com sucesso: game $($data.gameKey) qualidade $($data.quality)"
                Send-Json -Response $response -Object @{ status = 'ok' }
            }
            '^/api/games/reset$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Reset-LinaGameOptimization -GameKey $data.gameKey -WhatIf:$false
                Add-ServerLog "Revertido com sucesso: game $($data.gameKey)"
                Send-Json -Response $response -Object @{ status = 'ok' }
            }
            '^/api/apply$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Add-ServerLog 'Aplicando tweaks selecionados'
                foreach ($tweak in $data.tweaks) {
                    switch ($tweak.type) {
                        'system' {
                            Add-LinaSystemActionLogs -Key $tweak.key -Enabled $true
                            Set-LinaSystemTweak -Key $tweak.key -Enabled -WhatIf:$false
                        }
                        'network' {
                            Add-LinaNetworkActionLogs -Key $tweak.key -Enabled $true
                            Set-LinaNetworkTweak -Key $tweak.key -Enabled -WhatIf:$false
                        }
                        'kernel' {
                            Add-LinaKernelActionLogs -Key $tweak.key -Enabled $true
                            Set-LinaKernelTweak -Key $tweak.key -Enabled -WhatIf:$false
                        }
                        'debloat' {
                            Add-LinaDebloatActionLogs -Key $tweak.key
                            Invoke-LinaDebloat -Mode $tweak.key -WhatIf:$false
                        }
                    }
                    Add-ServerLog "Aplicado com sucesso: $($tweak.type) $($tweak.key)"
                }
                Send-Json -Response $response -Object @{ status = 'ok'; log = (Get-ServerLog) }
            }
            '^/api/revert$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Add-ServerLog 'Revertendo tweaks selecionados'
                $results = @()
                foreach ($tweak in $data.tweaks) {
                    switch ($tweak.type) {
                        'system' {
                            Add-LinaSystemActionLogs -Key $tweak.key -Enabled $false
                            Set-LinaSystemTweak -Key $tweak.key -Enabled:$false -WhatIf:$false
                            $results += "Revertido: system $($tweak.key)"
                        }
                        'network' {
                            Add-LinaNetworkActionLogs -Key $tweak.key -Enabled $false
                            Set-LinaNetworkTweak -Key $tweak.key -Enabled:$false -WhatIf:$false
                            $results += "Revertido: network $($tweak.key)"
                        }
                        'kernel' {
                            Add-LinaKernelActionLogs -Key $tweak.key -Enabled $false
                            Set-LinaKernelTweak -Key $tweak.key -Enabled:$false -WhatIf:$false
                            $results += "Revertido: kernel $($tweak.key)"
                        }
                        'debloat' {
                            $results += "Debloat sem suporte a reversão: $($tweak.key)"
                        }
                    }
                }
                foreach ($entry in $results) {
                    Add-ServerLog $entry
                }
                Send-Json -Response $response -Object @{ status = 'ok'; log = $results }
            }
            '^/api/logs$' {
                Send-Json -Response $response -Object (Get-ServerLog)
            }
            default {
                $response.StatusCode = 404
                $response.OutputStream.Close()
            }
        }
    } catch {
        Add-ServerLog "Erro: $_"
        $response.StatusCode = 500
        $response.OutputStream.Close()
    }
}
