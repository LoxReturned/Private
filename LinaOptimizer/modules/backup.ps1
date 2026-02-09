function Get-LinaBackupActions {
    param([string]$Language = 'pt-BR')
    $items = @(
                @{ Key = 'BackupRegistry'; TitlePT = 'Backup Registry'; TitleEN = 'Backup Registry'; DescPT = 'Salvar registro em arquivo.'; DescEN = 'Save registry to file.' },
        @{ Key = 'BackupConfigs'; TitlePT = 'Backup Configs'; TitleEN = 'Backup Configs'; DescPT = 'Salvar configs de jogos.'; DescEN = 'Backup game configs.' },
        @{ Key = 'RestoreAll'; TitlePT = 'Restore All'; TitleEN = 'Restore All'; DescPT = 'Restaurar backups.'; DescEN = 'Restore backups.' }
    )

    $items | ForEach-Object {
        [pscustomobject]@{
            Key = $_.Key
            Title = if ($Language -eq 'pt-BR') { $_.TitlePT } else { $_.TitleEN }
            Description = if ($Language -eq 'pt-BR') { $_.DescPT } else { $_.DescEN }
        }
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
            "$env:LOCALAPPDATA\Roblox",
            "$env:LOCALAPPDATA\FiveM",
            "$env:USERPROFILE\Documents\Rockstar Games\GTA V",
            "$env:USERPROFILE\Documents\Call of Duty Modern Warfare"
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
