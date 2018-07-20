function Remove-GitRepository {
    [CmdletBinding()]
    param
    (
        # The repository folder
		[string]$Folder
	)
	if (Test-Path $Folder) {
		Log "Removing repository $Folder"
		if (Test-Path "$Folder\.git") {
			ls $Folder\.git | % {
				if ($_.Mode.StartsWith('d')) {
					Remove-Item $_.FullName -Recurse -Force
				} else {
					Remove-Item $_.FullName
				}
			}
		}
		Start-Sleep -Seconds 1
		Remove-Item $Folder\ -Recurse -Force
	}
	Start-Sleep -Milliseconds 500
}
