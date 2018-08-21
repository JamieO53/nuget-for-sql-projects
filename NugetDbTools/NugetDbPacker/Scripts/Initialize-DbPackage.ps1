function Initialize-DbPackage
{
	<#.Synopsis
	Initialize the NuGet files for a SQL Server project
	.DESCRIPTION
	Creates the folders and configuration files for a SQL Server project Nuget package
		Creates a folder called NuGet in the folder containing the project file.
		The folder is first deleted if it already exists.
	.EXAMPLE
	Initialize-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath
	)
	$projectFolder = Split-Path -LiteralPath $ProjectPath -Resolve
	$nugetPath = Join-Path -Path $projectFolder -ChildPath 'Nuget'
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	$nugetSettings = Import-NuGetSettings -NugetConfigPath $configPath

	Initialize-Package -ProjectPath $ProjectPath -NugetSettings $nugetSettings -SolutionPath $SolutionPath
	Import-NuGetDb -ProjectPath $ProjectPath -ProjDbFolder "$projectFolder\Databases" -NugetDbFolder "$nugetPath\content\Databases" -NugetSpecPath "$nugetPath\Package.nuspec"
	Compress-Package -NugetPath $nugetPath
}