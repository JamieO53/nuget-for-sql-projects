function Get-SolutionPackages {
	<#.Synopsis
	Get the solution's dependency packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)
	$slnFolder = Split-Path $SolutionPath
	$localSource = Get-NuGetLocalSource

	Get-CSharpProjects -SolutionPath $SolutionPath | ? { $_.Project.EndsWith('Pkg') } | % {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		[xml]$proj = gc $projPath
		$proj.Project.ItemGroup.PackageReference | % {
			$package = $_.Include
			$version = $_.Version
			if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
				iex "nuget install $package -Version '$version' -Source '$localSource' -OutputDirectory '$ContentFolder' -ExcludeVersion"
			}
			Set-NuGetDependencyVersion -SolutionPath $SolutionPath -Dependency $_.Include -Version $_.Version
		}
	}
}