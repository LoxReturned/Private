function Get-LinaNetworkTweaks {
    param([string]$Language = 'pt-BR')
    $items = @(
        @{ Key = 'TCPNoDelay'; TitlePT = 'TCPNoDelay'; TitleEN = 'TCPNoDelay'; TitleES = 'TCPNoDelay'; TitleDE = 'TCPNoDelay'; DescPT = 'Reduz latência TCP.'; DescEN = 'Reduce TCP latency.'; DescES = 'Reduce la latencia TCP.'; DescDE = 'Reduziert TCP-Latenz.' },
        @{ Key = 'TcpAckFrequency'; TitlePT = 'TcpAckFrequency'; TitleEN = 'TcpAckFrequency'; TitleES = 'TcpAckFrequency'; TitleDE = 'TcpAckFrequency'; DescPT = 'Melhora resposta de ACK.'; DescEN = 'Improve ACK response.'; DescES = 'Mejora la respuesta de ACK.'; DescDE = 'Verbessert die ACK-Antwort.' },
        @{ Key = 'NetworkThrottle'; TitlePT = 'Network Throttle Off'; TitleEN = 'Network Throttle Off'; TitleES = 'Network Throttle Off'; TitleDE = 'Network Throttle Off'; DescPT = 'Desativa throttle de rede.'; DescEN = 'Disable network throttling.'; DescES = 'Desactiva el throttling de red.'; DescDE = 'Deaktiviert Netzwerk-Throttling.' },
        @{ Key = 'QoSDisable'; TitlePT = 'QoS Disable'; TitleEN = 'QoS Disable'; TitleES = 'QoS Disable'; TitleDE = 'QoS Disable'; DescPT = 'Remove QoS do sistema.'; DescEN = 'Disable QoS.'; DescES = 'Desactiva QoS.'; DescDE = 'Deaktiviert QoS.' },
        @{ Key = 'InterruptModeration'; TitlePT = 'Interrupt Moderation Off'; TitleEN = 'Interrupt Moderation Off'; TitleES = 'Interrupt Moderation Off'; TitleDE = 'Interrupt Moderation Off'; DescPT = 'Reduz jitter na placa.'; DescEN = 'Reduce NIC jitter.'; DescES = 'Reduce el jitter de la NIC.'; DescDE = 'Reduziert NIC-Jitter.' },
        @{ Key = 'RSS'; TitlePT = 'RSS'; TitleEN = 'RSS'; TitleES = 'RSS'; TitleDE = 'RSS'; DescPT = 'Ativa Receive Side Scaling.'; DescEN = 'Enable RSS.'; DescES = 'Activa Receive Side Scaling.'; DescDE = 'Aktiviert Receive Side Scaling.' },
        @{ Key = 'RSC'; TitlePT = 'RSC'; TitleEN = 'RSC'; TitleES = 'RSC'; TitleDE = 'RSC'; DescPT = 'Ativa Receive Segment Coalescing.'; DescEN = 'Enable RSC.'; DescES = 'Activa Receive Segment Coalescing.'; DescDE = 'Aktiviert Receive Segment Coalescing.' },
        @{ Key = 'ECN'; TitlePT = 'ECN Off'; TitleEN = 'ECN Off'; TitleES = 'ECN Off'; TitleDE = 'ECN Off'; DescPT = 'Desativa ECN.'; DescEN = 'Disable ECN.'; DescES = 'Desactiva ECN.'; DescDE = 'Deaktiviert ECN.' },
        @{ Key = 'Offload'; TitlePT = 'Offload Off'; TitleEN = 'Offload Off'; TitleES = 'Offload Off'; TitleDE = 'Offload Off'; DescPT = 'Desativa offload TCP.'; DescEN = 'Disable TCP offload.'; DescES = 'Desactiva el offload TCP.'; DescDE = 'Deaktiviert TCP-Offload.' },
        @{ Key = 'MTU1500'; TitlePT = 'MTU 1500'; TitleEN = 'MTU 1500'; TitleES = 'MTU 1500'; TitleDE = 'MTU 1500'; DescPT = 'Define MTU padrão.'; DescEN = 'Set default MTU.'; DescES = 'Define el MTU predeterminado.'; DescDE = 'Setzt das Standard-MTU.' },
        @{ Key = 'Buffers'; TitlePT = 'Buffers'; TitleEN = 'Buffers'; TitleES = 'Buffers'; TitleDE = 'Buffers'; DescPT = 'Ajuste de buffers TCP.'; DescEN = 'Tune TCP buffers.'; DescES = 'Ajusta los buffers TCP.'; DescDE = 'Stellt TCP-Buffer ein.' }
    )

    $items | ForEach-Object {
        $title = switch ($Language) {
            'pt-BR' { $_.TitlePT }
            'es-ES' { $_.TitleES }
            'de-DE' { $_.TitleDE }
            default { $_.TitleEN }
        }
        $description = switch ($Language) {
            'pt-BR' { $_.DescPT }
            'es-ES' { $_.DescES }
            'de-DE' { $_.DescDE }
            default { $_.DescEN }
        }
        [pscustomobject]@{
            Key = $_.Key
            Title = $title
            Description = $description
        }
    }
}

function Set-LinaNetworkTweak {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter()] [switch]$Enabled
    )

    $ifaceKey = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces'
    $interfaces = Get-ChildItem $ifaceKey -ErrorAction SilentlyContinue

    switch ($Key) {
        'TCPNoDelay' {
            if ($PSCmdlet.ShouldProcess('TCPNoDelay', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                foreach ($iface in $interfaces) {
                    New-ItemProperty -Path $iface.PSPath -Name 'TCPNoDelay' -Value $value -PropertyType DWord -Force | Out-Null
                }
            }
        }
        'TcpAckFrequency' {
            if ($PSCmdlet.ShouldProcess('TcpAckFrequency', 'Set')) {
                $value = if ($Enabled) { 1 } else { 2 }
                foreach ($iface in $interfaces) {
                    New-ItemProperty -Path $iface.PSPath -Name 'TcpAckFrequency' -Value $value -PropertyType DWord -Force | Out-Null
                }
            }
        }
        'NetworkThrottle' {
            if ($PSCmdlet.ShouldProcess('NetworkThrottle', 'Set')) {
                $value = if ($Enabled) { 0xffffffff } else { 10 }
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'QoSDisable' {
            if ($PSCmdlet.ShouldProcess('QoS', 'Set')) {
                $value = if ($Enabled) { 0 } else { 20 }
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched' -Name 'NonBestEffortLimit' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'InterruptModeration' {
            if ($PSCmdlet.ShouldProcess('InterruptModeration', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'EnableRSS' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'RSS' {
            if ($PSCmdlet.ShouldProcess('RSS', 'Set')) {
                $cmd = if ($Enabled) { 'netsh int tcp set global rss=enabled' } else { 'netsh int tcp set global rss=disabled' }
                cmd /c $cmd | Out-Null
            }
        }
        'RSC' {
            if ($PSCmdlet.ShouldProcess('RSC', 'Set')) {
                $cmd = if ($Enabled) { 'netsh int tcp set global rsc=enabled' } else { 'netsh int tcp set global rsc=disabled' }
                cmd /c $cmd | Out-Null
            }
        }
        'ECN' {
            if ($PSCmdlet.ShouldProcess('ECN', 'Set')) {
                $cmd = if ($Enabled) { 'netsh int tcp set global ecncapability=disabled' } else { 'netsh int tcp set global ecncapability=enabled' }
                cmd /c $cmd | Out-Null
            }
        }
        'Offload' {
            if ($PSCmdlet.ShouldProcess('Offload', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'DisableTaskOffload' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'MTU1500' {
            if ($PSCmdlet.ShouldProcess('MTU', 'Set')) {
                $cmd = if ($Enabled) { 'netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent' } else { 'netsh interface ipv4 set subinterface "Ethernet" mtu=1480 store=persistent' }
                cmd /c $cmd | Out-Null
            }
        }
        'Buffers' {
            if ($PSCmdlet.ShouldProcess('Buffers', 'Set')) {
                $cmd = if ($Enabled) { 'netsh int tcp set global autotuninglevel=normal' } else { 'netsh int tcp set global autotuninglevel=highlyrestricted' }
                cmd /c $cmd | Out-Null
            }
        }
    }
}
