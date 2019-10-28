if ( Get-Module VSTSExtension) {
	Remove-Module VSTSExtension
}
Import-Module "$PSScriptRoot\..\bin\Debug\VSTSExtension\VSTSExtension.psm1" -Global -DisableNameChecking

Describe "Test-IsRunningBuildAgent" {
	Context "Build agent service" {
		It "Is not running" {
			Test-IsRunningBuildAgent | Should Be ($env:USERNAME -eq 'Builder')
		}
	}
}