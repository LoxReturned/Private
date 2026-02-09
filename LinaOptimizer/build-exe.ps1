#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$OutputDir = 'dist',
    [switch]$BuildServer,
    [switch]$BuildDesktop
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$dist = Join-Path $root $OutputDir

if (Test-Path $dist) {
    Remove-Item -Path $dist -Recurse -Force
}
New-Item -Path $dist -ItemType Directory | Out-Null

@('modules', 'web', 'assets', 'logs') | ForEach-Object {
    $path = Join-Path $root $_
    if (Test-Path $path) {
        Copy-Item -Path $path -Destination (Join-Path $dist $_) -Recurse -Force
    }
}
Copy-Item -Path (Join-Path $root 'servidor.ps1') -Destination (Join-Path $dist 'servidor.ps1') -Force
Copy-Item -Path (Join-Path $root 'main.ps1') -Destination (Join-Path $dist 'main.ps1') -Force
Copy-Item -Path (Join-Path $root 'ui.xaml') -Destination (Join-Path $dist 'ui.xaml') -Force

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}
Import-Module ps2exe

if ($BuildServer -or -not ($BuildServer -or $BuildDesktop)) {
    $serverSource = Join-Path $dist 'servidor.ps1'
    $serverOut = Join-Path $dist 'LinaOptimizerServer.exe'
    Invoke-PS2EXE -InputFile $serverSource -OutputFile $serverOut -NoConsole -Force
}

if ($BuildDesktop) {
    $desktopSource = Join-Path $dist 'main.ps1'
    $desktopOut = Join-Path $dist 'LinaOptimizerDesktop.exe'
    Invoke-PS2EXE -InputFile $desktopSource -OutputFile $desktopOut -NoConsole -Force
}

Write-Host "Build concluído em $dist"
