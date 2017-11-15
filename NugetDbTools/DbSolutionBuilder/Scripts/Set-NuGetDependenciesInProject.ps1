function Set-NuGetDependenciesInProject {
	<#.Synopsis
	Sets the NuGet dependencies in the SQL project configuration file
	.DESCRIPTION
	Adds all the dependencies to the project's nuget.config file

	The modified project file is saved to disk
	.EXAMPLE
	Set-NuGetDependenciesInProject -Parameters $Parameters -ConfigPath "$projectFolder\$projectName.nuget.config"
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters,
		# The DB Project file path
		[string]$projectPath
	)
	$cfg = Import-NuGetSettings -Path $projectPath
	$Parameters.dbSolution.dependencies.dependency | % {
		$version = Get-NugetPackageVersion $_.id
		$cfg.nugetDependencies[$_.id] = $version
	}
	Export-NuGetSettings -ProjectPath $projectPath -Settings $cfg
}