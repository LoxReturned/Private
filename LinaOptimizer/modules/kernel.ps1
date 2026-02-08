function Get-LinaKernelTweaks {
    @(
        @{ Key = 'HPETOff'; Title = 'HPET OFF'; Description = 'Remove HPET do boot.' },
        @{ Key = 'DynamicTickOff'; Title = 'Dynamic Tick OFF'; Description = 'Desativa dynamic tick.' },
        @{ Key = 'MitigationsOff'; Title = 'Mitigations OFF'; Description = 'Desativa mitigations para performance.' },
        @{ Key = 'CETOff'; Title = 'CET OFF'; Description = 'Desativa Control-flow Enforcement.' },
        @{ Key = 'DEPOff'; Title = 'DEP OFF'; Description = 'Desativa DEP (use com cautela).' },
        @{ Key = 'CFGOff'; Title = 'CFG OFF'; Description = 'Desativa Control Flow Guard.' },
        @{ Key = 'CoreParkingOff'; Title = 'Core Parking OFF'; Description = 'Mantém cores ativos.' },
        @{ Key = 'InterruptAffinity'; Title = 'Interrupt Affinity'; Description = 'Ajusta afinidade de interrupções.' }
    ) | ForEach-Object { [pscustomobject]$_ }
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
                bcdedit /set useplatformclock no | Out-Null
            }
        }
        'DynamicTickOff' {
            if ($PSCmdlet.ShouldProcess('DynamicTick', 'Set')) {
                bcdedit /set disabledynamictick yes | Out-Null
            }
        }
        'MitigationsOff' {
            if ($PSCmdlet.ShouldProcess('Mitigations', 'Set')) {
                bcdedit /set mitigations Off | Out-Null
            }
        }
        'CETOff' {
            if ($PSCmdlet.ShouldProcess('CET', 'Set')) {
                bcdedit /set disablecet 1 | Out-Null
            }
        }
        'DEPOff' {
            if ($PSCmdlet.ShouldProcess('DEP', 'Set')) {
                bcdedit /set nx AlwaysOff | Out-Null
            }
        }
        'CFGOff' {
            if ($PSCmdlet.ShouldProcess('CFG', 'Set')) {
                Set-ProcessMitigation -System -Disable CFG
            }
        }
        'CoreParkingOff' {
            if ($PSCmdlet.ShouldProcess('CoreParking', 'Set')) {
                powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 | Out-Null
            }
        }
        'InterruptAffinity' {
            if ($PSCmdlet.ShouldProcess('InterruptAffinity', 'Set')) {
                New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Name 'IRQ8Priority' -Value 1 -PropertyType DWord -Force | Out-Null
            }
        }
    }
}
