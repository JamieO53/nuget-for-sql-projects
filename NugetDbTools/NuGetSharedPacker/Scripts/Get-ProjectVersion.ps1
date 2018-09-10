function Get-ProjectVersion {
<#.Synopsis
	Get the project's version
.DESCRIPTION
	Calculates the project's version from the git repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
.EXAMPLE
	$ver = Get-ProjectVersion -Path . -MajorVersion 1 -MinorVersion 0
#>
    [CmdletBinding()]
    param
    (
        # The project folder
		[string]$Path,
		# Build major version
		[string]$MajorVersion = '0',
		#build minor version
		[string]$MinorVersion = '0'

	)
	$majorVer = if ([string]::IsNullOrEmpty($MajorVersion)) { '0'} else { $MajorVersion }
	$minorVer = if ([string]::IsNullOrEmpty($MinorVersion)) { '0'} else { $MinorVersion }
	$latestTag = "$majorVer.$minorVer"
	[int]$revisions = Get-RevisionCount -Path $Path
		
	[string]$version = "$latestTag.$revisions"
		
	$branch = Get-Branch -Path $Path
	if ($branch -and ($branch -ne 'master')) {
		$version += "-$branch"
	}
		
	return $version
}

