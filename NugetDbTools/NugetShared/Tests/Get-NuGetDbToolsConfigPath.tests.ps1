if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}
Describe "Get-NuGetDbToolsConfigPath" {
	$toolConfigPath = "$TestDrive\solution\Powershell\..\PackageTools\PackageTools.root.config"
	$config = @"
	<?xml version="1.0"?>
	<tools>
		<junk>
			<trash>rubbish</trash>
		</junk>
	</tools>
"@
	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Debug" {
		It "Runs" {
			Get-NuGetDbToolsConfigPath | should -Be $toolConfigPath
		}
	}
}
