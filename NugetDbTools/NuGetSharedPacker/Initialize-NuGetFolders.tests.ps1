if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"
Describe 'Initialize-NuGetFolders' {
	$projFolder = 'TestDrive:\proj'
	$nugetFolder = "$projFolder\NuGet"
	$expectedFolders = 'tools','lib','content\Databases','build'
	Context "The NuGet folder exists" {
		$junkFolders = 'Junk1','Junk2\Rubbish'
		$junkData = @{'Leftover.txt'='Junk in root'; 'Junk1\Leftover1.txt'='Junk in Junk1'}
		$junkFolders | % { md "$nugetFolder\$_" }
		$junkData.Keys | % { $fn = $_; Add-Content -Path "$nugetFolder\$fn" -Value $junkData[$fn] }

		$junkFolders | % { Context "Junk $nugetFolder\$_" { It "junk should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
		$junkData.Keys | % { Context "Junk $nugetFolder\$_" {
			It "should be created" { (Test-Path "$nugetFolder\$_") | Should Be $true }
			It "should contain" { gc "$nugetFolder\$_" | Should Be $junkData[$_] }
		} }
		Initialize-NuGetFolders -Path $nugetFolder
		$junkFolders | % { Context "Junk $nugetFolder\$_" { It "should be removed" { (Test-Path "$nugetFolder\$_") | Should Be $false } } }

		$expectedFolders | % { Context "$nugetFolder\$_" { It "should be recreated" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
	Context "The NuGet folder doesn't exist" {
		Initialize-NuGetFolders -Path $nugetFolder
		$expectedFolders | % { Context "$nugetFolder\$_" { It "should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
}
