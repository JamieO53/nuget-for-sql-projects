function Set-NuGetDependenciesInPkgProject {
	<#.Synopsis
	Sets the NuGet dependencies in the SQL project configuration file
	.DESCRIPTION
	Adds all the dependencies to the project's nuget.config file

	The modified project file is saved to disk
	.EXAMPLE
	Set-NuGetDependenciesInPkgProject -Parameters $Parameters -ConfigPath "$projectFolder\$projectName.nuget.config"
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
	$cfgPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	$cfg = Import-NuGetSettings -NugetConfigPath $cfgPath
	$Parameters.dbSolution.dependencies.dependency | % {
		$version = Get-NugetPackageVersion $_.id
		$cfg.nugetDependencies[$_.id] = $version
	}
	Export-NuGetSettings -NugetConfigPath $cfgPath -Settings $cfg
}