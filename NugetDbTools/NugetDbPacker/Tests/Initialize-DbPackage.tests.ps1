if ( Get-Module NuGetDbPacker) {
	Remove-Module NuGetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetDbPacker\NuGetDbPacker.psm1"

if (Get-Module TestUtils -All) {
	Remove-Module TestUtils
}
Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1"

Describe 'Initialize-NuGetFolders' {
	$slnFolder = "$testdrive\sln"
	$projFolder = "$slnFolder\proj"
	$projDbFolder = "$projFolder\Databases"
	$nugetFolder = "$projFolder\NuGet"
	$expectedFolders = 'content\Databases'
	$slnPath = "$slnFolder\sln.sln"
	$projPath = "$projFolder\proj.sqlproj"
	$configPath = "$projFolder\proj.nuget.config"
	Context "The NuGet folder exists" {
		Initialize-TestDbProject -ProjectPath $projPath -NoDependencies

		$junkFolders = 'Junk1','Junk2\Rubbish'
		$junkData = @{'Leftover.txt'='Junk in root'; 'Junk1\Leftover1.txt'='Junk in Junk1'}
		$junkFolders | % { md "$nugetFolder\$_" }
		$junkData.Keys | % { $fn = $_; Add-Content -Path "$nugetFolder\$fn" -Value $junkData[$fn] }

		$junkFolders | % { Context "Junk $nugetFolder\$_" { It "junk should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
		$junkData.Keys | % { Context "Junk $nugetFolder\$_" {
			It "should be created" { (Test-Path "$nugetFolder\$_") | Should Be $true }
			It "should contain" { gc "$nugetFolder\$_" | Should Be $junkData[$_] }
		} }
		Initialize-DbPackage -ProjectPath $projPath -SolutionPath $slnPath
		$junkFolders | % { Context "Junk $nugetFolder\$_" { It "should be removed" { (Test-Path "$nugetFolder\$_") | Should Be $false } } }

		$expectedFolders | % { Context "$nugetFolder\$_" { It "should be recreated" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
	Context "The NuGet folder doesn't exist" {
		md $projDbFolder
		Initialize-TestProject $projPath -NoDependencies
		'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
		'lib' | Set-Content "$projDbFolder\ProjLib.dll"
		'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
		$nugetSettings = Initialize-TestNugetConfig -NoDependencies
		Export-NuGetSettings -NugetConfigPath $configPath -Settings $nugetSettings
		Initialize-DbPackage -ProjectPath $projPath -SolutionPath $slnPath
		$expectedFolders | % { Context "$nugetFolder\$_" { It "should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
}
