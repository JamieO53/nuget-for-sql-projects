function Publish-Package {
	<#.Synopsis
	Publish a NuGet package for the project to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of the project has been published.
    
    If not, a new package is created and is pushed to the NuGet server
	.EXAMPLE
	Publish-Package -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being published
        [string]$ProjectPath
	)
    $configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
    $projFolder = Split-Path $ProjectPath -Resolve
    $nugetFolder = [IO.Path]::Combine($projFolder, 'NuGet')
    $settings = Import-NuGetSettings -NugetConfigPath $configPath
    $id = $settings.nugetSettings.Id
    $version = $settings.nugetSettings.version
    if (-not (Test-NuGetVersionExists -Id $id -Version $version)) {
        $nugetPackage = [IO.Path]::Combine($nugetFolder, "$id.$version.nupkg")
        Initialize-Package -ProjectPath $ProjectPath -NugetSettings $settings
        Publish-NuGetPackage -PackagePath $nugetPackage
		Remove-NugetFolder $nugetFolder
    }
}