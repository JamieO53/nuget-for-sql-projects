function Initialize-NuGetSpec {
<#.Synopsis
	Creates the NuGet package specification file
.DESCRIPTION
	Create the Nuget package specification file and initializes its content
.EXAMPLE
	Initialize-NuGetSpec -Path C:\VSTS\EcsShared\SupportRoles\NuGet
#>
    [CmdletBinding()]
	param(
		# The NuGet path
		[string]$Path,
		# The values to be set in the NuGet spec
		[PSObject]$setting
	)
	$nuGetSpecPath = "$Path\Package.nuspec"

	if (-not (Test-Path $nuGetSpecPath)) {
		$id = $setting.nugetSettings['id']
		pushd $Path
		nuget spec $id
		Rename-Item "$Path\$id.nuspec" 'Package.nuspec'
		popd
	}
	[xml]$specDoc = Get-Content $nuGetSpecPath
    $metadata = $specDoc.package.metadata

	$nodes = @()
	$metadata.ChildNodes | where { -not $setting.nugetSettings.Contains($_.Name) } | % { $nodes += $_.Name }
	$nodes | % {
		$name = $_
		Remove-Node -parentNode $metadata -id $name
	}
	if ($metadata.dependencies) {
		Remove-Node -parentnode $metadata -id 'dependencies'
	}
	$setting.nugetSettings.Keys | % {
		$name = $_
		$value = $setting.nugetSettings[$name]
		Set-NodeText -parentNode $metadata -id $name -text $value
	}
	$depsNode = Add-Node -parentNode $metadata -id dependencies
	$setting.nugetDependencies.Keys | % {
		$dep = $_
		$ver = $setting.nugetDependencies[$dep]
		$depNode = Add-Node -parentNode $depsNode -id dependency
		$depNode.SetAttribute('id', $dep)
		$depNode.SetAttribute('version', $ver)
	}
	$contFilesNode = Add-Node -parentNode $metadata -id contentFiles
	$setting.nugetContents.Keys | % {
		$files = $_
		$attrs = $setting.nugetContents[$files]
		[xml]$node = "<files include=`"$files`" $attrs/>"
		$childNode = $contFilesNode.AppendChild($contFilesNode.OwnerDocument.ImportNode($node.FirstChild, $true))
	}
	Out-FormattedXml -Xml $specDoc -FilePath $nuGetSpecPath
}