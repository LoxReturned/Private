function Apply-PowerPlan {
    param([hashtable]$Options)
    if (Test-WhatIf $Options 'Apply Power Plan') { return }
    $guid = (powercfg -duplicatescheme SCHEME_MIN) -replace '\s',''
    powercfg -setacvalueindex $guid SUB_PROCESSOR PROCTHROTTLEMAX 100
    powercfg -setacvalueindex $guid SUB_USB USBSELECTIVE 0
    powercfg -setactive $guid
    Write-Log -Message 'Power plan applied.'
}
