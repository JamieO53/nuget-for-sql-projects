function Get-SolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
	$slnFolder = Split-Path -Path $SolutionPath
	Get-PkgProjects $SolutionPath | % {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		[xml]$proj = gc $projPath
		$proj.Project.ItemGroup.PackageReference | % {
			$package = $_.Include
			$version = $_.Version
			$reference[$package] = $version
		}
	}
}