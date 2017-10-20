if (-not (Get-Module NugetShared)) {
	Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"
}

Describe "Get-NuGetDbToolsConfigPath" {
	Context "Non Debug" {
		if (Test-Path variable:\global:testing) {
			$Global:testing = $false
		}
		It "Runs" {
			Get-NuGetDbToolsConfigPath | should be "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
		}
	}
	Context "Debug" {
		$Global:testing = $true
		It "Runs" {
			Get-NuGetDbToolsConfigPath | should be "TestDrive:\Configuration\NugetDbTools.config"
		}
	}
}