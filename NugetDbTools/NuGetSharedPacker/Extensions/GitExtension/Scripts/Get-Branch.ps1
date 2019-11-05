function Get-Branch {
    [CmdletBinding()]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (Invoke-Expression) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			$branch = Invoke-Expression 'git branch' | Where-Object { $_.StartsWith('* ') } | ForEach-Object { $_.Replace('* ', '') }
			# Check VSTS build agent branch
			if ($branch -like '(HEAD detached at *)') {
				if (Test-IsRunningBuildAgent) {
					$branch = $env:BUILD_SOURCEBRANCHNAME
				} else {
					$branch = ''
				}
			}
			if ($branch -eq 'master') {
				$branch = ''
			}
		} else {
			$branch = ''
		}
	}
	finally {
		Pop-Location
	}
	$branch	
}