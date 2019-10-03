if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1" -Global -DisableNameChecking
Describe 'Initialize-NuGetFolders' {
	$projFolder = 'TestDrive:\proj'
	$nugetFolder = "$projFolder\NuGet"
	$expectedFolders = 'tools','lib','content\Databases','build'
	Context "The NuGet folder exists" {
		$junkFolders = 'Junk1','Junk2\Rubbish'
		$junkData = @{'Leftover.txt'='Junk in root'; 'Junk1\Leftover1.txt'='Junk in Junk1'}
		$junkFolders | ForEach-Object { mkdir "$nugetFolder\$_" }
		$junkData.Keys | ForEach-Object { $fn = $_; Add-Content -Path "$nugetFolder\$fn" -Value $junkData[$fn] }

		$junkFolders | ForEach-Object { Context "Junk $nugetFolder\$_" { It "junk should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
		$junkData.Keys | ForEach-Object { Context "Junk $nugetFolder\$_" {
			It "should be created" { (Test-Path "$nugetFolder\$_") | Should Be $true }
			It "should contain" { Get-Content "$nugetFolder\$_" | Should Be $junkData[$_] }
		} }
		Initialize-NuGetFolders -Path $nugetFolder
		mkdir "$nugetFolder\tools" | Out-Null
		mkdir "$nugetFolder\lib" | Out-Null
		mkdir "$nugetFolder\content" | Out-Null
		mkdir "$nugetFolder\content\Databases" | Out-Null
		mkdir "$nugetFolder\build" | Out-Null
		$junkFolders | ForEach-Object { Context "Junk $nugetFolder\$_" { It "should be removed" { (Test-Path "$nugetFolder\$_") | Should Be $false } } }

		$expectedFolders | ForEach-Object { Context "$nugetFolder\$_" { It "should be recreated" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
	Context "The NuGet folder doesn't exist" {
		Initialize-NuGetFolders -Path $nugetFolder
		mkdir "$nugetFolder\tools" | Out-Null
		mkdir "$nugetFolder\lib" | Out-Null
		mkdir "$nugetFolder\content" | Out-Null
		mkdir "$nugetFolder\content\Databases" | Out-Null
		mkdir "$nugetFolder\build" | Out-Null
		$expectedFolders | ForEach-Object { Context "$nugetFolder\$_" { It "should be created" { (Test-Path "$nugetFolder\$_" -PathType Container) | Should Be $true } } }
	}
}
