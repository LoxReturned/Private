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
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = $_.Category; risk = $_.Risk; type = 'system' }
    }
    $network = Get-LinaNetworkTweaks -Language $language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Network'; risk = 'Médio'; type = 'network' }
    }
    $kernel = Get-LinaKernelTweaks -Language $language | ForEach-Object {
        [pscustomobject]@{ key = $_.Key; title = $_.Title; description = $_.Description; category = 'Kernel'; risk = 'Alto'; type = 'kernel' }
    }
    $system + $network + $kernel
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
            '^/api/apply$' {
                $body = New-Object IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $data = $body.ReadToEnd() | ConvertFrom-Json
                $body.Close()
                Add-ServerLog 'Aplicando tweaks selecionados'
                New-LinaRestorePoint -WhatIf:$false
                foreach ($tweak in $data.tweaks) {
                    switch ($tweak.type) {
                        'system' { Set-LinaSystemTweak -Key $tweak.key -Enabled -WhatIf:$false }
                        'network' { Set-LinaNetworkTweak -Key $tweak.key -Enabled -WhatIf:$false }
                        'kernel' { Set-LinaKernelTweak -Key $tweak.key -Enabled -WhatIf:$false }
                    }
                    Add-ServerLog "Applied: $($tweak.type) $($tweak.key)"
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
