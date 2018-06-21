function Get-Branch {
    [CmdletBinding()]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (iex) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		# Check VSTS build agent branch
		if ((Test-Path env:BUILD_SOURCEBRANCHNAME)) {
			$branch = env:BUILD_SOURCEBRANCHNAME
		}
		elseif (Test-PathIsInGitRepo -Path (Get-Location)) {
			$branch = iex 'git branch' | ? { $_.StartsWith('* ') } | % { $_.Replace('* ', '') }
		}
		else {
			$branch = ''
		}
	}
	finally {
		Pop-Location
	}
	$branch	
}