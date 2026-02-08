function Get-LinaNetworkTweaks {
    @(
        @{ Key = 'TCPNoDelay'; Title = 'TCPNoDelay'; Description = 'Reduz latência TCP para jogos.' },
        @{ Key = 'TcpAckFrequency'; Title = 'TcpAckFrequency'; Description = 'Melhora resposta de ACK.' },
        @{ Key = 'NetworkThrottle'; Title = 'Network Throttle Off'; Description = 'Desativa throttle de rede.' },
        @{ Key = 'QoSDisable'; Title = 'QoS Disable'; Description = 'Desativa limite QoS.' },
        @{ Key = 'InterruptModeration'; Title = 'Interrupt Moderation Off'; Description = 'Reduz jitter da placa de rede.' },
        @{ Key = 'BufferOptimize'; Title = 'Buffer Optimize'; Description = 'Ajuste de buffers para throughput.' }
    ) | ForEach-Object { [pscustomobject]$_ }
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
                foreach ($iface in $interfaces) {
                    New-ItemProperty -Path $iface.PSPath -Name 'TCPNoDelay' -Value 1 -PropertyType DWord -Force | Out-Null
                }
            }
        }
        'TcpAckFrequency' {
            if ($PSCmdlet.ShouldProcess('TcpAckFrequency', 'Set')) {
                foreach ($iface in $interfaces) {
                    New-ItemProperty -Path $iface.PSPath -Name 'TcpAckFrequency' -Value 1 -PropertyType DWord -Force | Out-Null
                }
            }
        }
        'NetworkThrottle' {
            if ($PSCmdlet.ShouldProcess('NetworkThrottle', 'Set')) {
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 0xffffffff -PropertyType DWord -Force | Out-Null
            }
        }
        'QoSDisable' {
            if ($PSCmdlet.ShouldProcess('QoS', 'Set')) {
                New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched' -Name 'NonBestEffortLimit' -Value 0 -PropertyType DWord -Force | Out-Null
            }
        }
        'InterruptModeration' {
            if ($PSCmdlet.ShouldProcess('InterruptModeration', 'Set')) {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Name 'EnableRSS' -Value 1 -Type DWord -Force
            }
        }
        'BufferOptimize' {
            if ($PSCmdlet.ShouldProcess('Buffers', 'Set')) {
                netsh int tcp set global autotuninglevel=normal | Out-Null
                netsh int tcp set global ecncapability=disabled | Out-Null
            }
        }
    }
}
