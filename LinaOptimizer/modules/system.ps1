function Test-LinaAdmin {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $current
    $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-LinaSystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $disk = Get-CimInstance Win32_DiskDrive | Where-Object { $_.MediaType -match 'SSD' } | Select-Object -First 1
    $net = Get-CimInstance Win32_NetworkAdapter | Where-Object { $_.NetEnabled } | Select-Object -First 1
    $bios = Get-CimInstance Win32_BIOS | Select-Object -First 1

    [pscustomobject]@{
        Windows = "$($os.Caption) $($os.Version)"
        CPU = $cpu.Name
        GPU = $gpu.Name
        RAM = "{0:N0} GB" -f ($os.TotalVisibleMemorySize / 1MB)
        SSD = if ($disk) { $disk.Model } else { 'Não detectado / Not detected' }
        Network = if ($net) { $net.Name } else { 'Não detectado / Not detected' }
        Account = "$env:USERDOMAIN\$env:USERNAME"
        BIOS = "$($bios.Manufacturer) $($bios.SMBIOSBIOSVersion)"
        Driver = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -ErrorAction SilentlyContinue).ReleaseId
    }
}

function Get-LinaSystemTweaks {
    @(
        @{ Key = 'DisableTelemetry'; Title = 'Desativar Telemetria / Disable Telemetry'; Description = 'Reduz coleta de dados e serviços de rastreamento.' },
        @{ Key = 'DisableAnimations'; Title = 'Desativar Animações / Disable Animations'; Description = 'Remove animações para liberar GPU/CPU.' },
        @{ Key = 'DisableGameDVR'; Title = 'Desativar GameDVR / Disable GameDVR'; Description = 'Desliga gravação em background do Windows.' },
        @{ Key = 'DisableIndexing'; Title = 'Desativar Indexação / Disable Indexing'; Description = 'Reduz I/O em disco e uso de CPU.' },
        @{ Key = 'DisableEdgeBackground'; Title = 'Desativar Edge Background'; Description = 'Evita Edge rodando em segundo plano.' },
        @{ Key = 'DisableUselessServices'; Title = 'Desativar Serviços Inúteis'; Description = 'Desliga serviços sem impacto gamer.' },
        @{ Key = 'OptimizeTimer'; Title = 'Otimizar Timer / Optimize Timer'; Description = 'Ajuste de timer para menor latência.' },
        @{ Key = 'EnableMSIMode'; Title = 'MSI Mode / MSI Mode'; Description = 'Ativa MSI em dispositivos críticos.' },
        @{ Key = 'DisableHPET'; Title = 'HPET Off / HPET Off'; Description = 'Desativa HPET para reduzir latência.' }
    ) | ForEach-Object { [pscustomobject]$_ }
}

function Set-LinaSystemTweak {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter()] [switch]$Enabled
    )
    switch ($Key) {
        'DisableTelemetry' {
            if ($PSCmdlet.ShouldProcess('Telemetry', 'Set')) {
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
                Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue
                Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
        'DisableAnimations' {
            if ($PSCmdlet.ShouldProcess('Animations', 'Set')) {
                Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value 0
                Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Name 'MinAnimate' -Value 0
            }
        }
        'DisableGameDVR' {
            if ($PSCmdlet.ShouldProcess('GameDVR', 'Set')) {
                Set-ItemProperty -Path 'HKCU:\System\GameConfigStore' -Name 'GameDVR_Enabled' -Value 0 -Type DWord -Force
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR' -Name 'AllowGameDVR' -Value 0 -Type DWord -Force
            }
        }
        'DisableIndexing' {
            if ($PSCmdlet.ShouldProcess('Indexing', 'Set')) {
                Stop-Service -Name 'WSearch' -Force -ErrorAction SilentlyContinue
                Set-Service -Name 'WSearch' -StartupType Disabled -ErrorAction SilentlyContinue
            }
        }
        'DisableEdgeBackground' {
            if ($PSCmdlet.ShouldProcess('Edge', 'Set')) {
                Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name 'BackgroundModeEnabled' -Value 0 -Type DWord -Force
            }
        }
        'DisableUselessServices' {
            if ($PSCmdlet.ShouldProcess('Services', 'Set')) {
                'SysMain','DiagTrack','MapsBroker' | ForEach-Object {
                    Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
                }
            }
        }
        'OptimizeTimer' {
            if ($PSCmdlet.ShouldProcess('Timer', 'Set')) {
                bcdedit /set useplatformclock no | Out-Null
                bcdedit /set disabledynamictick yes | Out-Null
            }
        }
        'EnableMSIMode' {
            if ($PSCmdlet.ShouldProcess('MSI', 'Set')) {
                Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\PCI' -Name 'MSISupported' -Value 1 -Type DWord -ErrorAction SilentlyContinue
            }
        }
        'DisableHPET' {
            if ($PSCmdlet.ShouldProcess('HPET', 'Set')) {
                bcdedit /deletevalue useplatformclock | Out-Null
            }
        }
    }
}
