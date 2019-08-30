function Get-ExtensionPaths {
	$configPath = "$PSScriptRoot\..\PackageTools\PackageTools.root.config"
	$extensions = @{}
	if (Test-Path $configPath) {
		[xml]$config = gc $configPath
		$config.tools.extensions.extension | % {
			$extensions[$_.name] = "$PSScriptRoot\$($_.path)"
		}
	}
	return $extensions
}