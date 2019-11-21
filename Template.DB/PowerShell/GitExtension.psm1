
function Get-Branch {
    [CmdletBinding()]
    param (
        # The project folder
		[string]$Path
	)
	# Note: use Invoke-Expression (Invoke-Expression) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		if (Test-PathIsInGitRepo -Path (Get-Location).Path) {
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

function Get-Label {
	<#.Synopsis
	Gets the highest Label or Tag for the current repository
	.DESCRIPTION
    Sorts the lables or tags in the current repository semantically, and returns the highest one.
    The label is assumed to be formated thus: "$prefix$version" or "$prefix$version-$branch" where $version is
    "$major.$minor.$patch", $patch is the project's commit count, and $branch is the repository branch.
    No branch is specified for the master branch.
    The $major, $minor and $patch values are sorted numerically, while the $branch values is sorted alphabetically.
    The label or tag with no branch is higher than those with
	.EXAMPLE
	Set-Label -Label v1.0.123
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [string]$Prefix
    )
    if ($Prefix) {
        $labels = git tag --list "$Prefix*" | Where-Object { $_ -match "^$Prefix[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\-.*)?" }
    } else {
        $labels = git tag --list | Where-Object { $_ -match '^[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\-.*)?' }
    } 
    $result = ''
    $result = $labels | ForEach-Object {
        $label = $_
        if ($Prefix) {
            $tail = $label.Replace($Prefix, '')
        } else {
            $tail = $label
        }
        $versionBranch = $tail.Split('-', 2)
        [string]$version = $versionBranch[0]
        if ($versionBranch.Count -eq 2) {
            [string]$branch = $versionBranch[1]
        } else {
            [string]$branch = [char]::MaxValue
        }
        $versionParts = $version.Split('.')
        [int]$major = $versionParts[0]
        [int]$minor = $versionParts[1]
        if ($versionParts.Count -gt 2) {
            [int]$patch = $versionParts[2]
            if ($versionParts.Count -gt 3) {
                [int]$build = $versionParts[3]
            } else {
                [int]$build = 0
            }
        } else {
            [int]$patch = 0
            [int]$build = 0
        }
        New-Object -TypeName PSCustomObject -Property @{
            major = $major
            minor = $minor
            patch = $patch
            build = $build
            branch = $branch
            label = $label
        }
    } | Sort-Object -Property major,minor,patch,build,branch -Descending | Select-Object -First 1 | ForEach-Object {
        $_.label
    }
    return $result
}

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
		if (Test-PathIsInGitRepo -Path (Get-Location).Path) {
			$rp = Resolve-GitPath $Path
			[int]$revisions = (Invoke-Expression "git rev-list $Label..HEAD -- $rp").Count
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
			Get-ChildItem $Folder\.git | ForEach-Object {
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

function Resolve-GitPath {
	<#.Synopsis
	Mormalizes the path
	.DESCRIPTION
	Ensures that the path matches the underlying path with a case-sensitive comparison
	.EXAMPLE
	(Resolve-GitPath c:\azuredevops\continuousintegration\nuget-for-sql-projects) -eq 'C:\AzureDevOps\ContinuousIntegration\nuget-for-sql-projects'
	#>
    [CmdletBinding()]
	[OutputType([string])]
    param (
        # The path being resolved
		[string]$Path
	)
	$folder = Split-Path $Path
	$subfolder = Split-Path $Path -Leaf
	return (Get-ChildItem $folder | Where-Object {$_.Name -eq $subfolder} ).FullName
}

function Set-Label {
	<#.Synopsis
	Sets the Label or Tag for the current repository
	.DESCRIPTION
    Sets the Label or Tag for the current repository.
    The label is assumed to be formated thus: "v$version" or "v$version-$branch" where $version is
    "$major.$minor.$patch", $patch is the project's commit count, and $branch is the repository branch.
    No branch is specified for the master branch.
	.EXAMPLE
	Set-Label -Label v1.0.123
	#>
    [CmdletBinding()]
    param (
        # The label text
		[string]$Label
	)
    git tag -a $label -m "Publish $Label"
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
		Push-Location $Path
		$rp = Resolve-GitPath $Path
		(Test-PathIsInGitRepo -Path .) -and ([string]::IsNullOrEmpty((Invoke-Expression "git status --porcelain -- $rp")))
	} finally {
		Pop-Location
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

function Update-ToRepository {
	<#.Synopsis
	Commits the changes
	.DESCRIPTION
    Commits changese to the given file to the current repository.
	.EXAMPLE
	Update-ToRepository -Path $projectFolder\Package.nuspec -Message 'BATCH update dependency versions'
	#>
    [CmdletBinding()]
    param (
        # The path of the file being committed
		[string]$Path,
		# The commit message
		[string]$Message
	)
	Invoke-Expression "git commit -m `"$Message`" -- $Path"
}


