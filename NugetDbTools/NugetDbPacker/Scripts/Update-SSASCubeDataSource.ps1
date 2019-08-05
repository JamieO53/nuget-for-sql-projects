function Update-SSASCubeDataSource {
	param (
		[string]$SSASCubeConfigSettingsPath,
		[string]$DataSourceConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeConfigSettingsPath)) {
			Write-Host "$SSASCubeConfigSettingsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DataSourceConfigPath)) {
			Write-Host "$DataSourceConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeConfigSettingsFileName = [IO.Path]::GetFileName($SSASCubeConfigSettingsPath)
		Write-Host "Updating $SSASCubeConfigSettingsFileName..."
		
		[xml]$SSASCubeConfigSettingsFile = Get-Content "$SSASCubeConfigSettingsPath"
		[xml]$dataSourceConfigFile = Get-Content "$DataSourceConfigPath"

		$configSettingsDataSources = $SSASCubeConfigSettingsFile.ConfigurationSettings.Database.DataSources.DataSource
		
		foreach ($dataSource in $dataSourceConfigFile.DataSources.DataSource) {
			$configSettingDataSource = $configSettingsDataSources | Where-Object { $_.ID -eq $dataSource.ID }
			$configSettingDataSource.ConnectionString = $dataSource.ConnectionString
		}

		$SSASCubeConfigSettingsFile.Save("$SSASCubeConfigSettingsPath")

		Write-Host "$SSASCubeConfigSettingsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDetails failed: $_" -Error
	}
}