function Apply-NetworkTweaks {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Apply Network Tweaks') { return }
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name TcpAckFrequency -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name TCPNoDelay -Type DWord -Value 1
    Set-ItemProperty -Path $path -Name NetworkThrottlingIndex -Type DWord -Value 0xffffffff
    Write-Log -Message 'Network tweaks applied.'
}
