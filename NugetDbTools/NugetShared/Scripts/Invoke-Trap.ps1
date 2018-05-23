function Invoke-Trap {
    [CmdletBinding()]
	param (
		[ScriptBlock]$Command,
		[string]$Message,
		[switch]$Fatal
	)
	$Command.InvokeReturnAsIs() 2> .\errors.txt
	if ($LASTEXITCODE -ne 0) {
		$caller = Get-Caller
		Log $Message -Error -taskStep $caller
		$errors = gc .\errors.txt
		$errors | % {
			Log $_ -Error -taskStep $caller
		}
		if ($Fatal) {
			throw $Message
		}
	}
	if (Test-Path .\errors.txt) {
		Remove-Item .\errors.txt
	}
}