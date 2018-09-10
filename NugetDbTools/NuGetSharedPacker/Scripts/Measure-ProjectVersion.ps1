function Measure-ProjectVersion {
<#.Synopsis
	Calculates the project's version from the local repository.
.DESCRIPTION
	Calculates the project's version from the local repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
.EXAMPLE
	$ver = Set-NuspecVersion -Path .\Package.nuspec
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The folder for version calculations
		[string]$ProjectFolder,
		# The previous version to be updated with the new revision number
		[string]$OldVersion = '1.0.0'
	)
	[xml]$cfg = gc $Path
	if (-not $oldVersion) {
		$oldVersion = '1.0.0'
	}
	$versionParts = $oldVersion.Split('.')
	$majorVersion = $versionParts[0]
	$minorVersion = $versionParts[1]
	Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion
}