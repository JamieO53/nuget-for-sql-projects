function Get-RevisionCount {
    [CmdletBinding()]
	[OutputType([int])]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (iex) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			[int]$revisions = (iex "git rev-list HEAD -- $Path").Count
		}
		else {
			[int]$revisions = 0
		}
	}
	finally {
		Pop-Location
	}
	$revisions	
}
