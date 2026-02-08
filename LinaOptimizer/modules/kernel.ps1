function Apply-KernelTweaks {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Apply Kernel Tweaks') { return }
    Ensure-Admin
    bcdedit /set disabledynamictick yes | Out-Null
    bcdedit /set nx OptOut | Out-Null
    bcdedit /set mitigations Off | Out-Null
    Write-Log -Message 'Kernel tweaks applied.'
}
