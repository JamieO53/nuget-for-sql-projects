function Get-RevisionCount {
    [CmdletBinding()]
	[OutputType([int])]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location).Path) {
			$rp = Resolve-GitPath $Path
			[int]$revisions = (Invoke-Expression "git rev-list HEAD -- `"$rp\*`"").Count
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
