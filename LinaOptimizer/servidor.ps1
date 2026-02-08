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

function Get-LinaTweaksPayload {
    $language = 'pt-BR'
    $system = Get-LinaSystemTweaks -Language $language | ForEach-Object {
        $group = Get-LinaCategoryGroup -Category $_.Category -Key $_.Key
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $_.Category; group = $group; risk = $_.Risk; type = 'system' }
    }
    $network = Get-LinaNetworkTweaks -Language $language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Network'; group = 'internet'; risk = 'Médio'; type = 'network' }
    }
    $kernel = Get-LinaKernelTweaks -Language $language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Kernel'; group = 'kernel'; risk = 'Alto'; type = 'kernel' }
    }
    $debloat = Get-LinaDebloatModes -Language $language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Debloat'; group = 'debloat'; risk = 'Alto'; type = 'debloat' }
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

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8787/')
$listener.Start()
Add-ServerLog 'Servidor iniciado em http://localhost:8787/'
try {
    Start-Process 'http://localhost:8787/'
} catch {
    Add-ServerLog "Falha ao abrir navegador: $_"
}

while ($listener.IsListening) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    try {
        switch -Regex ($request.Url.AbsolutePath) {
            '^/$' {
                Send-File -Response $response -Path (Join-Path $script:WebRoot 'index.html') -ContentType 'text/html; charset=utf-8'
            }
            '^/app.js$' {
                Send-File -Response $response -Path (Join-Path $script:WebRoot 'app.js') -ContentType 'application/javascript; charset=utf-8'
            }
            '^/api/hardware$' {
                $info = Get-LinaSystemInfo
                Send-Json -Response $response -Object $info
            }
            '^/api/tweaks$' {
                Send-Json -Response $response -Object (Get-LinaTweaksPayload)
            }
            '^/api/games$' {
                $games = Get-LinaGameProfiles -Language 'pt-BR' | ForEach-Object {
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
            '^/api/restorepoint$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                $name = if ($data -and $data.name) { $data.name } else { 'Lina Optimizer Restore Point' }
                $restore = New-LinaRestorePoint -Name $name -WhatIf:$false
                if ($restore -and $restore.Message) {
                    Add-ServerLog $restore.Message
                }
                Send-Json -Response $response -Object @{ status = if ($restore.Success) { 'ok' } else { 'error' }; message = $restore.Message }
            }
            '^/api/apply$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Add-ServerLog 'Aplicando tweaks selecionados'
                try {
                    $restore = New-LinaRestorePoint -WhatIf:$false
                    if ($restore -and $restore.Message) {
                        Add-ServerLog $restore.Message
                    }
                } catch {
                    Add-ServerLog "Restore point falhou: $_"
                }
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
