function Set-NuspecVersion {
<#.Synopsis
	Set the project's version in the Project.nuspec file
.DESCRIPTION
	Calculates the project's version from the git repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
	The updated version number is set in the .nuspec file, and the version is returned.
.EXAMPLE
	$ver = Set-NuspecVersion -Path .\Package.nuspec
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The folder for version calculations
		[string]$ProjectFolder
	)

	[xml]$cfg = gc Package.nuspec
	$oldVersion=$cfg.package.metadata.version
	$versionParts = $oldVersion.Split('.')
	$majorVersion = $versionParts[0]
	$minorVersion = $versionParts[1]
	$newVersion = Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion
	$cfgText = gc Package.nuspec | Out-String
	$cfgText =  $cfgText.Replace($oldVersion, $newVersion).TrimEnd()
	$cfgText | Out-File -FilePath .\Package.nuspec -Encoding utf8 -Force
	$newVersion
}