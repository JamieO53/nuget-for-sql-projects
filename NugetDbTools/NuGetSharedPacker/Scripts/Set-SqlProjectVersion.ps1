function Set-SqlProjectVersion {
	<#.Synopsis
	Set the DacVersion of all the solution's SQL projects
	.DESCRIPTION
    Edits all the solution's sqlproj files 
	.EXAMPLE
	Set-SqlProjectVersion -SolutionPath C:\VSTS\Batch\Batch.sln -Version 1.0.123
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The build package version
		[string]$Version
	)
	$solutionFolder = Split-Path $SolutionPath
	Get-SqlProjects $SolutionPath | ForEach-Object {
		$projPath = "$solutionFolder\$($_.ProjectPath)"
		$configPath = [IO.Path]::ChangeExtension($projPath, '.nuget.config')
		if (Test-Path $configPath) {
			$settings = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $SolutionPath
			$versionBranch = $settings.nugetSettings.version.Split('-',2)
			$version = $versionBranch[0]
			if ($versionBranch.Count -eq 2) {
				$version += '.0'
			}

			[xml]$proj = Get-Content -Path $projPath
			$parentNode = $proj.Project.PropertyGroup | Where-Object { $_.DacVersion }
			if (-not $parentNode) {
				$parentNode = $proj.Project.PropertyGroup | Where-Object { $_.ProjectGuid }
			}
			if ($parentNode) {
				Set-NodeText -parentNode $parentNode -id 'DacVersion' -text $version
				Out-FormattedXml -Xml $proj -FilePath $projPath
			}
		}
	}
}