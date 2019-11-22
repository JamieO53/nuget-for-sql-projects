if ( Get-Module NugetSharedPacker -All) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetSharedPacker\NugetSharedPacker.psm1" -Global -DisableNameChecking

if (Get-Module TestUtils -All) {
	Remove-Module TestUtils
}
Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking

Describe "Get-ProjectVersion" {
	$projFolder = "$TestDrive\proj"
	$projPath = "$projFolder\proj.sqlproj"

	Context "Not in git" {
		Initialize-TestDbProject -ProjectPath $projPath

		Push-Location $projFolder 
		It "version" { Get-ProjectVersion | should be '0.0.0' }
		Pop-Location
		Remove-Item TestDrive:* -Recurse -Force
	}
	Context "In git without" {
		mock Invoke-Expression { return 1..7 } -ParameterFilter { $Command -eq "git rev-list HEAD -- `"$projFolder\*`"" } -ModuleName GitExtension
		Initialize-TestDbProject -ProjectPath $projPath

		Push-Location 'TestDrive:\'
		git init
		It "version" { Get-ProjectVersion -Path $projFolder | should be '0.0.7' }
		Pop-Location
		Remove-Item TestDrive:* -Recurse -Force
	}
	Context "In git branch" {
		mock Invoke-Expression { return 1..7 } -ParameterFilter { $Command -eq "git rev-list HEAD -- `"$projFolder\*`"" } -ModuleName GitExtension
		Initialize-TestDbProject -ProjectPath $projPath

		Push-Location 'TestDrive:\'
		try {
			git init
			'Dummy' | Set-Content "$projFolder\Dummy.txt" -Encoding UTF8
			git add .\proj\Dummy.txt
			git commit -a -m Initial
			git branch TestBranch
			git checkout TestBranch 2> $null
			It "version" { Get-ProjectVersion -Path $projFolder -MajorVersion 1 -MinorVersion 0 | should be '1.0.7-TestBranch' }
		} finally {
			Pop-Location
			Remove-Item TestDrive:* -Recurse -Force
		}
	}
}
