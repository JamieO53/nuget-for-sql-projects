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
		[string]$OldVersion,
		# Increase the version by 1
		[bool]$UpVersion = $false
	)
	if (-not $oldVersion) {
		if (Test-Path $Path) {
			[xml]$cfg = Get-Content $Path
			$OldVersion = $cfg.package.metadata.version
			if (-not $oldVersion) {
				$oldVersion = '1.0.0'
			}
		} else {
			$oldVersion = '1.0.0'
		}
	}
	[string[]]$versionParts = $oldVersion.Split('.',3)
	[string]$majorVersion = $versionParts[0]
	[string]$minorVersion = $versionParts[1]
	$minorVersion = $minorVersion.Split('-',2)[0]
	Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion -UpVersion $UpVersion
}