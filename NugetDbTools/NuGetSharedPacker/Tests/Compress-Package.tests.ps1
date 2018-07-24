if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

Describe "Compress-Package" {
	$projFolder = "$testDrive\proj"
	$projDbFolder = "$projFolder\Databases"
	$projPath = "$projFolder\proj.sqlproj"
	$configPath = "$projFolder\proj.nuget.config"
	$nugetFolder = "$projFolder\NuGet"
	$nugetSpecPath = "$nugetFolder\Package.nuspec"
	$projText = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<Project DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`" ToolsVersion=`"4.0`">
  <PropertyGroup>
    <DacApplicationName>ProjDb</DacApplicationName>
  </PropertyGroup>
  <PropertyGroup>
    <Configuration Condition=`" '`$(Configuration)' == '' `">Debug</Configuration>
    <AssemblyName>ProjLib</AssemblyName>
  </PropertyGroup>
</Project>
"@
mkdir "$testDrive\.git"
Context "Exists" {
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName GitExtension
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName GitExtension
		mkdir $projDbFolder
		mkdir $nugetFolder
		$projText | Set-Content $projPath
		$nugetSettings = Initialize-TestNugetConfig -NoDependencies
		Export-NuGetSettings -NugetConfigPath $configPath -Settings $nugetSettings

		'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
		'lib' | Set-Content "$projDbFolder\ProjLib.dll"
		'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
		Initialize-Package -ProjectPath $projPath
		Compress-Package -NugetPath $nugetFolder

		$id = $nugetSettings.nugetSettings.id
		$version = $nugetSettings.nugetSettings.version
		It "$id.$version.nupkg exists" { Test-Path "$nugetFolder\$id.$version.nupkg" | should be $true }

		Remove-Item "$projFolder*" -Recurse -Force
		Remove-Item "$testDrive\.git*" -Recurse -Force
	}
}