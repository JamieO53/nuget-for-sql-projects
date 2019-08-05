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
			-SSASCubeConfigSettingsPath "$ConfigFolder\$CubeName.configsettings" `
			-DataSourceConfigPath "$ConfigFolder\DataSources.configsettings"

		Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$CubeFolder\$CubeName.asdatabase`" `"$DatabaseName`"" -Message $DeploymentError -Fatal
	}
}