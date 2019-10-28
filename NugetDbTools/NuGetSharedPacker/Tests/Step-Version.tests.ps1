if ( Get-Module NugetSharedPacker) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetSharedPacker\NugetSharedPacker.psm1" -Global -DisableNameChecking

Describe "Step-Version" {
	Context "Exists" {
		It "Test for function" {
			Test-Path function:Step-Version | Should be $true
		}
		It "Increases master version" {
			Step-Version 1.0.123 | Should be 1.0.124
		}
		It "Increases branch version" {
			Step-Version 1.0.123-Branch | Should be 1.0.124-Branch
		}
	}
}