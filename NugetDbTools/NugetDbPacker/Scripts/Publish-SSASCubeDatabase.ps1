function Publish-SSASCubeDatabase {
	param (
		[string]$CubeFolder,
		[string]$CubeName,
		[string]$ConfigSharedFolder,
		[string]$ConfigFolder,
		[string]$DatabaseName,
		[string]$DeploymentError
	)
	if (Test-Path "$ConfigFolder") {
		Update-SSASCubeAsdatabaseFile `
			-SSASCubeAsdatabasePath "$CubeFolder\$CubeName.asdatabase" `
			-DeploymentTargetConfigPath "$ConfigFolder\$CubeName.deploymenttargets"

		Update-SSASCubeDeploymentOptions `
			-SSASCubeDeploymentOptionsPath "$CubeFolder\$CubeName.deploymentoptions" `
			-DeploymentOptionsConfigPath "$ConfigSharedFolder\default.deploymentoptions"

		Update-SSASCubeDeploymentTarget `
			-SSASCubeDeploymentTargetsPath "$CubeFolder\$CubeName.deploymenttargets" `
			-DeploymentTargetConfigPath "$ConfigFolder\$CubeName.deploymenttargets"

		Update-SSASCubeDataSource `
			-SSASCubeConfigSettingsPath "$CubeFolder\$CubeName.configsettings" `
			-DataSourceConfigPath "$ConfigFolder\DataSources.configsettings"

		[string]$TargetServerVersion = "2016"

		if(Test-Path -Path "$ConfigFolder\AdditionalSettings.xml") {
		    [xml]$SSASCubeAdditionalSettingsFile = Get-Content "$ConfigFolder\AdditionalSettings.xml"
			if (-not $SSASCubeAdditionalSettingsFile.Settings.Server.Version) {
				Write-Host "SSAS Target server version variable not defined, defaulting to $TargetServerVersion" -fore red
			} else {
				$TargetServerVersion = $SSASCubeAdditionalSettingsFile.Settings.Server.Version;
			}
		} else {
		    Write-Host "Additional settings file was not defined for this target deployment channel" -fore yellow
		}
		
		Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$CubeFolder\$CubeName.asdatabase`" `"$DatabaseName`" `"$TargetServerVersion`"" -Message $DeploymentError -Fatal
	}
}