function Publish-SolutionDbPackages {
	<#.Synopsis
	Publish a NuGet package for each DB project in the solution to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of each DB project has been published.
    
    If not, a new package is created for them and are pushed to the NuGet server
	.EXAMPLE
	Publish-SolutionDbPackages -ProjectPath C:\VSTS\EcsShared\EcsShared.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being published
        [string]$SolutionPath
	)
    $solutionFolder = Split-Path -Path $SolutionPath

    Get-SqlProjects -SolutionPath $SolutionPath | % {
        [string]$projectPath = [IO.Path]::Combine($solutionFolder, $_.ProjectPath)
        Publish-DbPackage -ProjectPath $projectPath -SolutionPath $SolutionPath
    }
}