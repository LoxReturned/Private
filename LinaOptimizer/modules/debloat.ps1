function Invoke-Debloat {
    param([string]$Level, [hashtable]$Options)
    if (Test-WhatIf $Options "Debloat $Level") { return }
    Ensure-Admin
    $apps = @('Microsoft.XboxApp','Microsoft.BingNews','Microsoft.GetHelp')
    if ($Level -eq 'Medium' -or $Level -eq 'Nuclear') { $apps += 'Microsoft.OneDriveSync' }
    if ($Level -eq 'Nuclear') { $apps += 'Microsoft.WindowsCamera','Microsoft.People' }
    foreach ($app in $apps) {
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    }
    Write-Log -Message "Debloat $Level applied."
}
