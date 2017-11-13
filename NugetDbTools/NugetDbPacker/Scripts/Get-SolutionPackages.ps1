function Get-SolutionPackages (
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Set-NuGetDependencyVersion -SolutionPath C:\VSTS\Batch\Batch.sln -Dependency 'BackOfficeStateManager.StateManager' -Version '0.1.2'
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)
	$localSource = Get-NuGetLocalSource

	Get-CSharpProjects -SolutionPath $slnPath | ? { $_.Project.EndsWith('Pkg') } | % {
		$projPath = "$SolutionFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		[xml]$proj = gc $projPath
		$proj.Project.ItemGroup.PackageReference | % {
			$package = $_.Include
			$version = $_.Version
			nuget install $package -Version $version -Source $localSource -OutputDirectory $ContentFolder -ExcludeVersion
		}
	}
)