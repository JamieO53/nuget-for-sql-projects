function Get-ToolsConfiguration {
	$configPath = Get-NuGetDbToolsConfigPath
	$tools = @()
	if (Test-Path $configPath) {
		[xml]$config = Get-Content $configPath
		if ($config.tools) {
			$tools += $config.tools
		}
	}
	$tools
}