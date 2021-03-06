﻿if ( Get-Module NugetSharedPacker) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetSharedPacker.psm1" -Global -DisableNameChecking
if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1" -Global -DisableNameChecking
if (-not (Get-Module TestUtils)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global
}

Describe "Import-NuGetDb" {
	$slnFolder
	$projFolder = "TestDrive:\proj"
	$projDbFolder = "$projFolder\Databases"
	$projPath = "$projFolder\proj.sqlproj"
	$nugetFolder = "$projFolder\NuGet"
	$nugetDbFolder = "$nugetFolder\content\Databases"
	$nugetSpecPath = "$nugetFolder\Package.nuspec"
	$nugetSettings = Initialize-TestNugetConfig
	Context "Files setting in nuget spec" {
		Initialize-TestDbProject -ProjectPath $projPath
		Initialize-NuGetFolders -Path $nugetFolder
		mkdir $nugetDbFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjDbFolder $projDbFolder -NugetDbFolder $nugetDbFolder -NugetSpecPath $nugetSpecPath
		[xml]$spec = Get-Content "$nugetFolder\Package.nuspec"

		It "Files group should exist" { $spec.package.SelectNodes('files') | should not BeNullOrEmpty }
		It "File node should exist" { $spec.package.files.SelectNodes('file') | should not BeNullOrEmpty }
		Context "File node content" {
			$fileNode = $spec.package.files.SelectSingleNode('file')
			It "Source" { $fileNode.src | should be 'content\Databases\**' }
			It "Target" { $fileNode.target | should be 'Databases' }
		}

		Remove-Item -Path $projFolder -Recurse -Force
	}
	Context "Import project build files" {
		Initialize-TestDbProject -ProjectPath $projPath
		Initialize-NuGetFolders -Path $nugetFolder
		mkdir $nugetDbFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjDbFolder $projDbFolder -NugetDbFolder $nugetDbFolder -NugetSpecPath $nugetSpecPath
		
		It "Dacpac imported" { Test-Path "$nugetDbFolder\ProjDb.dacpac" | should be $true }
		It "Lib imported" { Test-Path "$nugetDbFolder\ProjLib.dll" | should be $true }
		It "Pdb imported" { Test-Path "$nugetDbFolder\ProjLib.pdb" | should be $true }
		Remove-Item -Path $projFolder -Recurse -Force
	}
}