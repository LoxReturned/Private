function Get-LinaDebloatModes {
    param([string]$Language = 'pt-BR')
    $modes = @(
        @{ Key = 'Light'; TitlePT = 'Leve'; TitleEN = 'Light'; TitleES = 'Ligero'; TitleDE = 'Leicht'; DescPT = 'Remoção segura de apps básicos.'; DescEN = 'Safe removal of basic apps.'; DescES = 'Eliminación segura de apps básicas.'; DescDE = 'Sichere Entfernung grundlegender Apps.' },
        @{ Key = 'Medium'; TitlePT = 'Médio'; TitleEN = 'Medium'; TitleES = 'Medio'; TitleDE = 'Mittel'; DescPT = 'Balanceado para performance.'; DescEN = 'Balanced for performance.'; DescES = 'Balanceado para rendimiento.'; DescDE = 'Ausgewogen für Performance.' },
        @{ Key = 'Extreme'; TitlePT = 'Nuclear'; TitleEN = 'Extreme'; TitleES = 'Extremo'; TitleDE = 'Extrem'; DescPT = 'Remoção agressiva, use com cautela.'; DescEN = 'Aggressive removal, use with caution.'; DescES = 'Eliminación agresiva, úsalo con cuidado.'; DescDE = 'Aggressive Entfernung, mit Vorsicht nutzen.' }
    )

    $modes | ForEach-Object {
        $title = switch ($Language) {
            'pt-BR' { "$($_.TitlePT) / $($_.TitleEN)" }
            'es-ES' { "$($_.TitleES) / $($_.TitleEN)" }
            'de-DE' { "$($_.TitleDE) / $($_.TitleEN)" }
            default { "$($_.TitleEN) / $($_.TitlePT)" }
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

function Invoke-LinaDebloat {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory)] [ValidateSet('Light','Medium','Extreme')] [string]$Mode
    )

    $appxBase = @(
        'Microsoft.BingNews',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.People',
        'Microsoft.SkypeApp',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.XboxApp',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo'
    )

    $appxMedium = @('Microsoft.OneConnect','Microsoft.MicrosoftOfficeHub','Microsoft.YourPhone')
    $appxExtreme = @('Microsoft.WindowsMaps','Microsoft.MicrosoftStickyNotes','Microsoft.XboxGamingOverlay')

    $targets = $appxBase
    if ($Mode -in @('Medium','Extreme')) {
        $targets += $appxMedium
    }
    if ($Mode -eq 'Extreme') {
        $targets += $appxExtreme
    }

    if ($PSCmdlet.ShouldProcess("Debloat $Mode", 'Remove Appx')) {
        foreach ($app in $targets) {
            Get-AppxPackage -AllUsers -Name $app | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -eq $app } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
    }

    if ($Mode -ne 'Light' -and $PSCmdlet.ShouldProcess('Services', 'Disable')) {
        'DiagTrack','WSearch','SysMain','WaaSMedicSvc','RetailDemo','MapsBroker' | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

    if ($Mode -in @('Medium','Extreme') -and $PSCmdlet.ShouldProcess('Tasks', 'Disable')) {
        '\\Microsoft\\Windows\\Customer Experience Improvement Program\\Consolidator',
        '\\Microsoft\\Windows\\Application Experience\\ProgramDataUpdater',
        '\\Microsoft\\Windows\\DiskDiagnostic\\Microsoft-Windows-DiskDiagnosticDataCollector' |
        ForEach-Object { schtasks /Change /TN $_ /Disable | Out-Null }
    }

    if ($Mode -eq 'Extreme' -and $PSCmdlet.ShouldProcess('Windows Update', 'Disable')) {
        Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue
        Set-Service -Name 'wuauserv' -StartupType Disabled -ErrorAction SilentlyContinue
    }

    if ($PSCmdlet.ShouldProcess('Telemetry', 'Block')) {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
    }

    if ($Mode -ne 'Light' -and $PSCmdlet.ShouldProcess('OneDrive', 'Remove')) {
        $oneDrive = "$env:SystemRoot\\System32\\OneDriveSetup.exe"
        if (Test-Path $oneDrive) {
            Start-Process $oneDrive '/uninstall' -Wait
        }
    }
}

function Invoke-LinaDiscordDebloat {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $paths = @(
        "$env:APPDATA\discord\Cache",
        "$env:APPDATA\discord\Code Cache",
        "$env:APPDATA\discord\GPUCache",
        "$env:LOCALAPPDATA\Discord\SquirrelTemp"
    )

    if ($PSCmdlet.ShouldProcess('Discord', 'Debloat')) {
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
