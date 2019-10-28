function Invoke-Trap {
    [CmdletBinding()]
	param (
		[string]$Command,
		[string]$Message,
		[switch]$Fatal
	)
	try {
		Invoke-Expression "$Command 2> .\errors.txt"
		if ($LASTEXITCODE -ne 0) {
			$caller = Get-Caller
			Log $Message -Error -taskStep $caller
			$errors = Get-Content .\errors.txt
			$errors | ForEach-Object {
				Log $_ -Error -taskStep $caller -allowLayout
			}
			if ($Fatal) {
				throw $Message
			}
		}
	} finally {
		if (Test-Path .\errors.txt) {
			Remove-Item .\errors.txt
		}
	}
}