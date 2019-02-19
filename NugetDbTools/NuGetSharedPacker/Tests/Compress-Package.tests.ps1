if (Get-Module NuGetSharedPacker -All) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

if (Get-Module TestUtils -All) {
	Remove-Module TestUtils
}
Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1"

Describe "Compress-Package" {
	$projFolder = "$testDrive\proj"
	$projDbFolder = "$projFolder\Databases"
	$projPath = "$projFolder\proj.sqlproj"
	$configPath = "$projFolder\proj.nuget.config"
	$nugetFolder = "$projFolder\NuGet"
	$nugetSpecPath = "$nugetFolder\Package.nuspec"
mkdir "$testDrive\.git"
Context "Exists" {
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- `"$projFolder\*`"" } -ModuleName GitExtension
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName GitExtension
		Initialize-TestDbProject -ProjectPath $projPath -NoDependencies
		mkdir $nugetFolder
		$nugetSettings = Initialize-TestNugetConfig -NoDependencies
		Initialize-Package -ProjectPath $projPath -NugetSettings $nugetSettings
		mkdir "$nugetFolder\tools" | Out-Null
		mkdir "$nugetFolder\lib" | Out-Null
		mkdir "$nugetFolder\content" | Out-Null
		mkdir "$nugetFolder\content\Databases" | Out-Null
		mkdir "$nugetFolder\build" | Out-Null
		Compress-Package -NugetPath $nugetFolder

		$id = $nugetSettings.nugetSettings.id
		$version = $nugetSettings.nugetSettings.version
		It "$id.$version.nupkg exists" { Test-Path "$nugetFolder\$id.$version.nupkg" | should be $true }

		Remove-Item "$projFolder*" -Recurse -Force
		Remove-Item "$testDrive\.git*" -Recurse -Force
	}
}