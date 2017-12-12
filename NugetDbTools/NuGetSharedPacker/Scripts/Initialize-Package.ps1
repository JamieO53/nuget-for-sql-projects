function Initialize-Package
{
	<#.Synopsis
	Initialize the NuGet files for a Visual Studio project
	.DESCRIPTION
	Creates the folders and configuration files for a Visual Studio project Nuget package
		Creates a folder called NuGet in the folder containing the project file.
		The folder is first deleted if it already exists.
	.EXAMPLE
	Initialize-Package -ProjectPath C:\VSTS\Ethel\Ethel\Ethel.csproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .*proj file of the project being packaged
        [string]$ProjectPath
	)
	$projectFolder = Split-Path -LiteralPath $ProjectPath -Resolve
	$nugetPath = Join-Path -Path $projectFolder -ChildPath 'Nuget'
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	Initialize-NuGetFolders -Path $nugetPath
	$nugetSettings = Import-NuGetSettings -NugetConfigPath $configPath
	Initialize-NuGetSpec -Path $nugetPath -setting $nugetSettings
}