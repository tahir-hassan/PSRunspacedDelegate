Add-Type -Path "$PSScriptRoot\RunspacedDelegateFactory.cs"

Function New-RunspacedDelegate {
    param([Parameter(Mandatory=$true)][System.Delegate]$Delegate, [Runspace]$Runspace=[Runspace]::DefaultRunspace)

    [PowerShell.RunspacedDelegateFactory]::NewRunspacedDelegate($Delegate, $Runspace);
}

