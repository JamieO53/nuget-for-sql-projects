function Set-NuspecDependencyVersion {
<#.Synopsis
	Set the dependency's version in the Project.nuspec file to the latest version on the server.
.DESCRIPTION
	Fetches the dependency's latest version number and sets it in the .nuspec file.
.EXAMPLE
	Set-NuspecDependencyVersion -Path .\Package.nuspec -Dependency NugetDbPacker
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The dependency name
		[string]$Dependency,
		# The optional Branch - Prerelease label
		[string]$Branch = $null
	)

	[xml]$spec = Get-Content $Path
	$dependencies = $spec.package.metadata.dependencies
	[xml.XmlElement]$dependencies = Get-GroupNode -ParentNode $spec.package.metadata -Id 'dependencies'
	$newVersion = Get-NuGetPackageVersion -PackageName $Dependency -Branch $Branch
	$dep = $dependencies.dependency | Where-Object { $_.id -eq $Dependency }
	if ($dep) {
		$dep.SetAttribute('version', $newVersion)
	} else {
		$newDep = Add-Node -parentNode $dependencies -id 'dependency'
		$newDep.SetAttribute('id', $Dependency)
		$newDep.SetAttribute('version', $newVersion)
	}
	Out-FormattedXml -Xml $spec -FilePath $Path
}