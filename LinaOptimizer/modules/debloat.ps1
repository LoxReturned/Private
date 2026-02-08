function Get-LinaDebloatModes {
    @(
        @{ Key = 'Light'; Title = 'Leve / Light' },
        @{ Key = 'Medium'; Title = 'Médio / Medium' },
        @{ Key = 'Extreme'; Title = 'Nuclear / Extreme' }
    ) | ForEach-Object { [pscustomobject]$_ }
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
        'DiagTrack','WSearch','SysMain' | ForEach-Object {
            Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
            Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

    if ($Mode -eq 'Extreme' -and $PSCmdlet.ShouldProcess('Windows Update', 'Disable')) {
        Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue
        Set-Service -Name 'wuauserv' -StartupType Disabled -ErrorAction SilentlyContinue
    }

    if ($PSCmdlet.ShouldProcess('Telemetry', 'Block')) {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -Type DWord -Force
    }
}
