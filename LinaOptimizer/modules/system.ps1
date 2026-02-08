function Test-IsAdmin {
    $current = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $current.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Ensure-Admin {
    if (-not (Test-IsAdmin)) {
        Write-Log -Message 'Admin required / Admin necessário.' -Level ERROR
        throw 'Admin required.'
    }
}

function Disable-Telemetry {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable Telemetry') { return }
    Ensure-Admin
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name AllowTelemetry -Type DWord -Value 0
    Write-Log -Message 'Telemetry disabled.'
}

function Disable-Animations {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable Animations') { return }
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name MenuShowDelay -Value 0
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name MinAnimate -Value 0
    Write-Log -Message 'Animations disabled.'
}

function Disable-GameDVR {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable GameDVR') { return }
    New-Item -Path 'HKCU:\System\GameConfigStore' -Force | Out-Null
    Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name GameDVR_Enabled -Type DWord -Value 0
    Write-Log -Message 'GameDVR disabled.'
}

function Disable-Indexing {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable Indexing') { return }
    Ensure-Admin
    Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
    Set-Service -Name WSearch -StartupType Disabled
    Write-Log -Message 'Indexing disabled.'
}

function Disable-EdgeBackground {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable Edge Background') { return }
    $path = 'HKLM:\SOFTWARE\Policies\Microsoft\Edge'
    New-Item -Path $path -Force | Out-Null
    Set-ItemProperty -Path $path -Name BackgroundModeEnabled -Type DWord -Value 0
    Write-Log -Message 'Edge background disabled.'
}

function Disable-UnusedServices {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable Unused Services') { return }
    Ensure-Admin
    $services = 'SysMain','DiagTrack','MapsBroker','RetailDemo'
    foreach ($svc in $services) {
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
    }
    Write-Log -Message 'Unused services disabled.'
}

function Optimize-Timer {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Optimize Timer') { return }
    Ensure-Admin
    bcdedit /set useplatformtick yes | Out-Null
    Write-Log -Message 'Timer optimized.'
}

function Enable-MSIMode {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Enable MSI Mode') { return }
    Ensure-Admin
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI'
    Get-ChildItem $path -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
        $msi = Join-Path $_.PsPath 'Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'
        if (Test-Path $msi) {
            New-Item -Path $msi -Force | Out-Null
            Set-ItemProperty -Path $msi -Name MSISupported -Type DWord -Value 1 -ErrorAction SilentlyContinue
        }
    }
    Write-Log -Message 'MSI mode enabled.'
}

function Disable-HPET {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Disable HPET') { return }
    Ensure-Admin
    bcdedit /set useplatformclock no | Out-Null
    Write-Log -Message 'HPET disabled.'
}
