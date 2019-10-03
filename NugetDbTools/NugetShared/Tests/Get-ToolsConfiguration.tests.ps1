Describe "Get-ToolsConfiguration" {
	Context "Default test location" {
		if (Get-Module NugetShared) {
			Remove-Module NugetShared
		}
		Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking
		It "Exists" {
			Get-Item function:Get-ToolsConfiguration | should not be $null
		}
		$config = Get-ToolsConfiguration
		It "Has content" {
			$config | ForEach-Object {$_.rubbish} | should be 'junk'
		}
	}
}