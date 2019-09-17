function Get-ToolsConfiguration {
	$configPath = Get-NuGetDbToolsConfigPath
	$tools = @()
	if (Test-Path $configPath) {
		[xml]$config = gc $configPath
		if ($config.tools) {
			$tools += $config.tools
		}
	}
	$tools
}