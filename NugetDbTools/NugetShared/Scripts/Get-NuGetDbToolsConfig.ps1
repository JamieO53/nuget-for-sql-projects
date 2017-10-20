function Get-NuGetDbToolsConfig {
	[xml]$config = Get-Content (Get-NuGetDbToolsConfigPath)
	Return $config
}
