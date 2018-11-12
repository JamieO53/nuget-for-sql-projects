function Initialize-TestDbProject {
	param (
		[string]$ProjectPath,
		[switch]$NoDependencies
	)
	$projFolder = Split-Path $ProjectPath
	$projDbFolder = [IO.Path]::Combine($projFolder, 'Databases')
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	md $projDbFolder
	Initialize-TestProject -ProjectPath $ProjectPath 
	
	if ($NoDependencies) {
		$nugetSettings = Initialize-TestNugetConfig -NoDependencies 
	} else {
		$nugetSettings = Initialize-TestNugetConfig
	}
	
	Export-NuGetSettings -NugetConfigPath $configPath -Settings $nugetSettings

	'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
	'lib' | Set-Content "$projDbFolder\ProjLib.dll"
	'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
}