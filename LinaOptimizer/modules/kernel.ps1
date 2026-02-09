function Get-LinaKernelTweaks {
    param([string]$Language = 'pt-BR')
    $items = @(
        @{ Key = 'HPETOff'; TitlePT = 'HPET OFF'; TitleEN = 'HPET OFF'; DescPT = 'Remove HPET do boot.'; DescEN = 'Disable HPET at boot.' },
        @{ Key = 'DynamicTickOff'; TitlePT = 'Dynamic Tick OFF'; TitleEN = 'Dynamic Tick OFF'; DescPT = 'Desativa dynamic tick.'; DescEN = 'Disable dynamic tick.' },
        @{ Key = 'MitigationsOff'; TitlePT = 'Mitigations OFF'; TitleEN = 'Mitigations OFF'; DescPT = 'Desativa mitigations.'; DescEN = 'Disable mitigations.' },
        @{ Key = 'CETOff'; TitlePT = 'CET OFF'; TitleEN = 'CET OFF'; DescPT = 'Desativa CET.'; DescEN = 'Disable CET.' },
        @{ Key = 'DEPOff'; TitlePT = 'DEP OFF'; TitleEN = 'DEP OFF'; DescPT = 'Desativa DEP.'; DescEN = 'Disable DEP.' },
        @{ Key = 'CFGOff'; TitlePT = 'CFG OFF'; TitleEN = 'CFG OFF'; DescPT = 'Desativa CFG.'; DescEN = 'Disable CFG.' },
        @{ Key = 'CoreParkingOff'; TitlePT = 'Core Parking OFF'; TitleEN = 'Core Parking OFF'; DescPT = 'Mantém cores ativos.'; DescEN = 'Keep cores active.' },
        @{ Key = 'InterruptAffinity'; TitlePT = 'IRQ Affinity'; TitleEN = 'IRQ Affinity'; DescPT = 'Ajusta afinidade de IRQ.'; DescEN = 'Adjust IRQ affinity.' },
        @{ Key = 'PowerThrottlingOff'; TitlePT = 'Power Throttling OFF'; TitleEN = 'Power Throttling OFF'; DescPT = 'Desativa throttling.'; DescEN = 'Disable throttling.' },
        @{ Key = 'MSIMode'; TitlePT = 'MSI Mode'; TitleEN = 'MSI Mode'; DescPT = 'Ativa MSI global.'; DescEN = 'Enable global MSI.' }
    )

    $items | ForEach-Object {
        [pscustomobject]@{
            Key = $_.Key
            Title = if ($Language -eq 'pt-BR') { $_.TitlePT } else { $_.TitleEN }
            Description = if ($Language -eq 'pt-BR') { $_.DescPT } else { $_.DescEN }
        }
    }
}

function Set-LinaKernelTweak {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter()] [switch]$Enabled
    )

    switch ($Key) {
        'HPETOff' {
            if ($PSCmdlet.ShouldProcess('HPET', 'Set')) {
                $cmd = if ($Enabled) { 'bcdedit /set useplatformclock no' } else { 'bcdedit /deletevalue useplatformclock' }
                cmd /c $cmd | Out-Null
            }
        }
        'DynamicTickOff' {
            if ($PSCmdlet.ShouldProcess('DynamicTick', 'Set')) {
                $cmd = if ($Enabled) { 'bcdedit /set disabledynamictick yes' } else { 'bcdedit /deletevalue disabledynamictick' }
                cmd /c $cmd | Out-Null
            }
        }
        'MitigationsOff' {
            if ($PSCmdlet.ShouldProcess('Mitigations', 'Set')) {
                $cmd = if ($Enabled) { 'bcdedit /set mitigations Off' } else { 'bcdedit /deletevalue mitigations' }
                cmd /c $cmd | Out-Null
            }
        }
        'CETOff' {
            if ($PSCmdlet.ShouldProcess('CET', 'Set')) {
                $cmd = if ($Enabled) { 'bcdedit /set disablecet 1' } else { 'bcdedit /deletevalue disablecet' }
                cmd /c $cmd | Out-Null
            }
        }
        'DEPOff' {
            if ($PSCmdlet.ShouldProcess('DEP', 'Set')) {
                $cmd = if ($Enabled) { 'bcdedit /set nx AlwaysOff' } else { 'bcdedit /deletevalue nx' }
                cmd /c $cmd | Out-Null
            }
        }
        'CFGOff' {
            if ($PSCmdlet.ShouldProcess('CFG', 'Set')) {
                $cmd = if ($Enabled) { 'powershell -Command "Set-ProcessMitigation -System -Disable CFG"' } else { 'powershell -Command "Set-ProcessMitigation -System -Enable CFG"' }
                cmd /c $cmd | Out-Null
            }
        }
        'CoreParkingOff' {
            if ($PSCmdlet.ShouldProcess('CoreParking', 'Set')) {
                $cmd = if ($Enabled) { 'powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100' } else { 'powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 10' }
                cmd /c $cmd | Out-Null
            }
        }
        'InterruptAffinity' {
            if ($PSCmdlet.ShouldProcess('InterruptAffinity', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'IRQ8Priority' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'PowerThrottlingOff' {
            if ($PSCmdlet.ShouldProcess('PowerThrottling', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' -Name 'PowerThrottlingOff' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
        'MSIMode' {
            if ($PSCmdlet.ShouldProcess('MSI', 'Set')) {
                $value = if ($Enabled) { 1 } else { 0 }
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Pnp\PnpResources' -Name 'EnableIRQ64' -Value $value -PropertyType DWord -Force | Out-Null
            }
        }
    }
}
