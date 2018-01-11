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
	if (-not $oldVersion) {
		$oldVersion = '1.0.0'
	}
	$versionParts = $oldVersion.Split('.')
	$majorVersion = $versionParts[0]
	$minorVersion = $versionParts[1]
	$newVersion = Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion
	[xml]$cfg = gc Package.nuspec
	#$oldText = "<version>$oldVersion</version>"
	#$newText = "<version>$newVersion</version>"
	#$cfgText =  $cfgText.Replace($oldText, $newText).TrimEnd()
	Set-NodeText -parentNode $cfg.package.metadata -id version -text $newVersion
	$cfgText | Out-File -FilePath .\Package.nuspec -Encoding utf8 -Force
	$newVersion
}