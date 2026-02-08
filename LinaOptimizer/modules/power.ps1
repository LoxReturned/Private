function New-LinaPowerPlan {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    if ($PSCmdlet.ShouldProcess('PowerPlan', 'Create')) {
        $guid = (powercfg -duplicatescheme SCHEME_MIN) -replace 'Power Scheme GUID: ', ''
        powercfg -changename $guid 'Lina Max Performance' 'Lina Optimizer plan'
        powercfg -setacvalueindex $guid sub_processor PROCTHROTTLEMAX 100
        powercfg -setacvalueindex $guid sub_pciexpress ASPM 0
        powercfg -setacvalueindex $guid sub_usb USBSELECTIVE 0
        powercfg -setacvalueindex $guid sub_sleep STANDBYIDLE 0
        powercfg -setacvalueindex $guid sub_sleep HYBRIDSLEEP 0
        powercfg -setactive $guid
    }
}
