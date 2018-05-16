function Remove-GitRepository {
    [CmdletBinding()]
    param
    (
        # The repository folder
		[string]$Path
	)
	if (Test-path $Path) {
		Log "Removing repository $Path"
		if (Test-Path "$Path\.git") {
			ls $Path\.git | % {
				if ($_.Mode.StartsWith('d')) {
					Remove-Item $_.FullName -Recurse -Force
				} else {
					Remove-Item $_.FullName
				}
			}
		}
		Start-Sleep -Seconds 1
		Remove-Item $Path\ -Recurse -Force
	}
	Start-Sleep -Milliseconds 500
}
