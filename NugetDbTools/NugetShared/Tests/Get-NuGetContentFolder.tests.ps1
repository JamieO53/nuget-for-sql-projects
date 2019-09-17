if (-not (Get-Module TestUtils -All)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}
$config = @"
<?xml version="1.0"?>
<tools>
	<content>
		<contentFolder>Runtime</contentFolder>
	</content>
</tools>
"@
Describe "Get-NuGetContentFolder" {

	Initialize-NuGetSharedConfig $PSScriptRoot $config
	Context "Exists" {
		It "Runs" {
			Get-NuGetContentFolder | should be 'Runtime' #'Content Folder'
		}
	}
}
