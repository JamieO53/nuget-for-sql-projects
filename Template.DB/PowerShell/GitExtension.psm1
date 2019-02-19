
function Get-Branch {
    [CmdletBinding()]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (iex) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			$branch = iex 'git branch' | ? { $_.StartsWith('* ') } | % { $_.Replace('* ', '') }
			# Check VSTS build agent branch
			if ($branch -like '(HEAD detached at *)') {
				if (Test-IsRunningBuildAgent) {
					$branch = $env:BUILD_SOURCEBRANCHNAME
				} else {
					$branch = ''
				}
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
			[int]$revisions = (iex "git rev-list HEAD -- `"$Path\*`"").Count
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

function Remove-Repository {
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

function Test-PathIsCommitted {
	<#.Synopsis
	Test if the Path has been committed
	.DESCRIPTION
	Checks if the path is in a git repo and has been committed
	.EXAMPLE
	if (Test-PathIsCommitted -Path C:\VSTS\EcsShared\SupportRoles)
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The path being tested
		[string]$Path
	)
	try {
		pushd $Path
		(Test-PathIsInGitRepo -Path .) -and ([string]::IsNullOrEmpty((iex 'git status --porcelain')))
	} finally {
		popd
	}
}

function Test-PathIsInGitRepo {
	<#.Synopsis
	Test if the Path is in a Git repository
	.DESCRIPTION
	Search the Path and its parents until the .git folder is found
	.EXAMPLE
	if (Test-PathIsInGitRepo -Path C:\VSTS\EcsShared\SupportRoles)
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The path being tested
		[string]$Path
	)
	[string]$myPath = Get-ParentSubfolder -Path $Path -Filter '.git'
	return $myPath -ne ''
}


