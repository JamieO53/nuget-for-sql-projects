function Get-LogPath {
    [CmdletBinding()]
	param (
		[string]$Name
	)
	$logFolder = "$(Split-Path $MyInvocation.PSScriptRoot)\Logs"
	if (-not (Test-Path $logFolder)) {
		md $logFolder
	}
	"$logFolder\$Name-$((Get-Date).ToString('yyyy-MM-dd-HH-mm-ss-fff')).log"
}
