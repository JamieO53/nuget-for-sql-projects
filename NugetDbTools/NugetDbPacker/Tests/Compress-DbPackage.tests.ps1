if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"

Describe "Compress-DbPackage" {
	$projFolder = "$testDrive\proj"
	$projDbFolder = "$projFolder\Databases"
	$projPath = "$projFolder\proj.sqlproj"
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
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NugetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName NugetShared
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName NugetShared
		mkdir $projDbFolder
		mkdir $nugetFolder
		$projText | Set-Content $projPath
		$nugetSettings = Initialize-TestNugetConfig -NoDependencies
		Export-NuGetSettings -ProjectPath $projPath -Settings $nugetSettings

		'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
		'lib' | Set-Content "$projDbFolder\ProjLib.dll"
		'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
		Initialize-DbPackage -ProjectPath $projPath
		Compress-DbPackage -NugetPath $nugetFolder

		$id = $nugetSettings.nugetSettings.id
		$version = $nugetSettings.nugetSettings.version
		It "$id.$version.nupkg exists" { Test-Path "$nugetFolder\$id.$version.nupkg" | should be $true }

		Remove-Item "$projFolder*" -Recurse -Force
		Remove-Item "$testDrive\.git*" -Recurse -Force
	}
}