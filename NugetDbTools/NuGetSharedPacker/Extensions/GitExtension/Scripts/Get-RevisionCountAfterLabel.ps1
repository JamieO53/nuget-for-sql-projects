function Get-RevisionCountAfterLabel {
    [CmdletBinding()]
	[OutputType([int])]
    param (
        # The project folder
		[string]$Path,
		# The label
		[string]$Label
	)
	# Note: use Invoke-Expression so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			[int]$revisions = (Invoke-Expression "git rev-list $Label..HEAD -- `"$Path\*`"").Count
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
