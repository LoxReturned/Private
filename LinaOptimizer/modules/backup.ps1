function Get-LinaBackupActions {
    param([string]$Language = 'pt-BR')
    $items = @(
        @{ Key = 'RestorePoint'; TitlePT = 'Restore Point'; TitleEN = 'Restore Point'; DescPT = 'Criar ponto de restauração.'; DescEN = 'Create system restore point.' },
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

function New-LinaRestorePoint {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()
    if (-not (Test-LinaRestorePointSupport)) {
        return [pscustomobject]@{
            Success = $false
            Message = 'Restore point indisponível: System Restore desativado.'
        }
    }
    if ($PSCmdlet.ShouldProcess('RestorePoint', 'Create')) {
        try {
            Checkpoint-Computer -Description 'Lina Optimizer Restore Point' -RestorePointType 'MODIFY_SETTINGS'
            return [pscustomobject]@{
                Success = $true
                Message = 'Restore point criado com sucesso.'
            }
        } catch {
            return [pscustomobject]@{
                Success = $false
                Message = "Restore point falhou: $_"
            }
        }
    }
    return [pscustomobject]@{
        Success = $false
        Message = 'Restore point não executado.'
    }
}

function Test-LinaRestorePointSupport {
    $systemDrive = if ($env:SystemDrive) { "$($env:SystemDrive)\" } else { 'C:\' }
    $policy = Get-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -ErrorAction SilentlyContinue
    if ($policy.DisableSR -eq 1) {
        try {
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\SystemRestore' -Name 'DisableSR' -Value 0 -Force -ErrorAction SilentlyContinue
        } catch {
            return $false
        }
    }
    $service = Get-Service -Name 'srservice' -ErrorAction SilentlyContinue
    if (-not $service) {
        return $false
    }
    if ($service.StartType -eq 'Disabled') {
        try {
            Set-Service -Name 'srservice' -StartupType Manual -ErrorAction SilentlyContinue
        } catch {
            return $false
        }
    }
    if ($service.Status -ne 'Running') {
        try {
            Start-Service -Name 'srservice' -ErrorAction SilentlyContinue
        } catch {
            return $false
        }
    }
    try {
        Enable-ComputerRestore -Drive $systemDrive -ErrorAction SilentlyContinue | Out-Null
    } catch {
        return $false
    }
    return $true
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
