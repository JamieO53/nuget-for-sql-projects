function Get-ToolsConfiguration {
	$configPath = "$PSScriptRoot\..\PackageTools\PackageTools.root.config"
	if (-not (Test-Path $configPath)) {
		## Testing - look in test scripts folder
		$configPath = "$PSScriptRoot\..\..\..\Tests\PackageTools.root.config"
		# $configPath = "$((Split-Path (Get-PSCallStack |
		# 	? {$_.Command -like '*.test.ps1' } |
		# 	select -Last 1).ScriptName))\PackageTools.root.config"
	}
	$tools = @()
	if (Test-Path $configPath) {
		[xml]$config = gc $configPath
		if ($config.tools) {
			$tools += $config.tools
		}
	}
	$tools
}