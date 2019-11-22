function Get-NuGetDbToolsConfigPath {
	if ($Global:ConfigPath -and (Test-Path $Global:ConfigPath)) {
		$Global:ConfigPath
	} else {
		$configPath = "$PSScriptRoot\..\PackageTools\PackageTools.root.config"
		if (-not (Test-Path $configPath)) {
			## Release - look parent folder
			$configPath = "$PSScriptRoot\..\PackageTools.root.config"
			if (-not (Test-Path $configPath)) {
				## Testing - look in test scripts folder
				$configPath = "$PSScriptRoot\..\..\..\Tests\PackageTools.root.config"
				if (-not (Test-Path $configPath)) {
					Log 'Unable to find Package Tools configuration: PackageTools.root.config' -Error
					Throw 'Missing configuration'
				}
			}
		}
		$configPath
	}
}
