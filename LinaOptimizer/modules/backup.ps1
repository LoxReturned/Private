function New-RestorePoint {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Create Restore Point') { return }
    Ensure-Admin
    Checkpoint-Computer -Description 'Lina Optimizer Restore' -RestorePointType 'MODIFY_SETTINGS'
    Write-Log -Message 'Restore point created.'
}

function Backup-Registry {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Backup Registry') { return }
    $target = Join-Path $Script:LogPath "registry-backup-$(Get-Date -Format yyyyMMdd-HHmmss).reg"
    reg export HKLM $target /y | Out-Null
    Write-Log -Message 'Registry backup created.'
}

function Backup-Configs {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Backup Configs') { return }
    $target = Join-Path $Script:LogPath "configs-backup-$(Get-Date -Format yyyyMMdd-HHmmss).zip"
    $paths = @("$env:LOCALAPPDATA\VALORANT", "$env:APPDATA\.minecraft") | Where-Object { Test-Path $_ }
    if ($paths) { Compress-Archive -Path $paths -DestinationPath $target -Force }
    Write-Log -Message 'Configs backup created.'
}

function Restore-All {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Restore All') { return }
    Write-Log -Message 'Restore All requested (manual steps required).'
}
