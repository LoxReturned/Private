function New-LinaRestorePoint {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if ($PSCmdlet.ShouldProcess('RestorePoint', 'Create')) {
        Checkpoint-Computer -Description 'Lina Optimizer Restore Point' -RestorePointType 'MODIFY_SETTINGS'
    }
}

function Backup-LinaRegistry {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $backupRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\logs'
    $file = Join-Path $backupRoot "registry-backup-$(Get-Date -Format yyyyMMdd-HHmmss).reg"
    if ($PSCmdlet.ShouldProcess('Registry', 'Backup')) {
        reg export HKLM $file /y | Out-Null
    }
}

function Backup-LinaGameConfigs {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    $backupRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) '..\logs'
    $dest = Join-Path $backupRoot "game-configs-$(Get-Date -Format yyyyMMdd-HHmmss)"
    if ($PSCmdlet.ShouldProcess('GameConfigs', 'Backup')) {
        New-Item -Path $dest -ItemType Directory -Force | Out-Null
        $paths = @(
            "$env:APPDATA\Valorant",
            "$env:LOCALAPPDATA\FortniteGame",
            "$env:APPDATA\.minecraft",
            "$env:LOCALAPPDATA\Roblox"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) {
                Copy-Item -Path $p -Destination (Join-Path $dest (Split-Path $p -Leaf)) -Recurse -Force
            }
        }
    }
}

function Restore-LinaAll {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if ($PSCmdlet.ShouldProcess('Restore', 'All')) {
        Write-Output 'Restauração manual necessária para backups gerados.'
    }
}
