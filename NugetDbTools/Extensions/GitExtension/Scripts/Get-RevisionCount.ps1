function Get-RevisionCount {
    [CmdletBinding()]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (iex) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			$revisions = (iex "git rev-list HEAD -- $Path").Count
		}
		else {
			$revisions = '0'
		}
	}
	finally {
		Pop-Location
	}
	$revisions	
}
