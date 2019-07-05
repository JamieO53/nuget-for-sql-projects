function Publish-NuGetPackage {
	<#.Synopsis
	Pushes the package to the 
	.DESCRIPTION
	Exports the settings to the project's NuGet configuration file
	.EXAMPLE
	Publish-NuGetPackage -PackagePath "$projDir\$id.$version.nupkg"
	#>
    [CmdletBinding()]
    param
    (
        # The location of the package being published
        [string]$PackagePath
	)
	$localSource = Get-NuGetLocalPushSource
	if (Test-Path $localSource) {
		nuget add $PackagePath -Source $localSource -NonInteractive
	} else {
		$apiKey = Get-NuGetLocalApiKey
		nuget push $PackagePath $apiKey -Source $localSource -t 900
	}
}