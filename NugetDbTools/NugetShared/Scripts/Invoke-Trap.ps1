function Invoke-Trap {
    [CmdletBinding()]
	param (
		[string]$Command,
		[string]$Message,
		[switch]$Fatal
	)
	try {
		iex "$Command 2> .\errors.txt"
		if ($LASTEXITCODE -ne 0) {
			$caller = Get-Caller
			Log $Message -Error -taskStep $caller
			$errors = gc .\errors.txt
			$errors | % {
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