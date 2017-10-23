﻿if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

Describe "Get-ProjectVersion" {
	$projFolder = "TestDrive:\proj"

	Context "Not in git" {
		mkdir $projFolder
		Push-Location $projFolder 
		It "version" { Get-ProjectVersion | should be '0.0.0' }
		Pop-Location
		rmdir TestDrive:* -Recurse -Force
	}
	Context "In git without" {
		mock Invoke-Expression { return 1..7 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName NugetShared
		mkdir $projFolder
		Push-Location 'TestDrive:\'
		git init
		It "version" { Get-ProjectVersion -Path $projFolder | should be '0.0.7' }
		Pop-Location
		rmdir TestDrive:* -Recurse -Force
	}
	Context "In git branch" {
		mock Invoke-Expression { return 1..7 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName NugetShared
		mkdir $projFolder
		Push-Location 'TestDrive:\'
		git init
		'Dummy' | sc "$projFolder\Dummy.txt"
		git add .\proj\Dummy.txt
		git commit -a -m Initial
		git branch TestBranch
		git checkout TestBranch 2> $null
		It "version" { Get-ProjectVersion -Path $projFolder -MajorVersion 1 -MinorVersion 0 | should be '1.0.7-TestBranch' }
		Pop-Location
		rmdir TestDrive:* -Recurse -Force
	}
}
