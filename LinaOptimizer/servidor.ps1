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
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Kernel'; group = 'cpu'; risk = 'Alto'; type = 'kernel' }
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
        'kernel|energia|power|cpu|scheduler|memory' { return 'cpu' }
        'drivers|gpu' { return 'gpu' }
        'system|sistema|ui|tasks|serviços|services|update|security|segurança' { return 'system' }
        default { return 'extra' }
    }
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add('http://localhost:8787/')
$listener.Start()
Add-ServerLog 'Servidor iniciado em http://localhost:8787/'

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
            '^/api/apply$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Add-ServerLog 'Aplicando tweaks selecionados'
                try {
                    New-LinaRestorePoint -WhatIf:$false
                } catch {
                    Add-ServerLog "Restore point falhou: $_"
                }
                foreach ($tweak in $data.tweaks) {
                    switch ($tweak.type) {
                        'system' { Set-LinaSystemTweak -Key $tweak.key -Enabled -WhatIf:$false }
                        'network' { Set-LinaNetworkTweak -Key $tweak.key -Enabled -WhatIf:$false }
                        'kernel' { Set-LinaKernelTweak -Key $tweak.key -Enabled -WhatIf:$false }
                        'debloat' { Invoke-LinaDebloat -Mode $tweak.key -WhatIf:$false }
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
