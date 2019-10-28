function Update-SSASCubeDeploymentTarget {
	param (
		[string]$SSASCubeDeploymentTargetsPath,
		[string]$DeploymentTargetConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentTargetsPath)) {
			Write-Host "$SSASCubeDeploymentTargetsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentTargetsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentTargetsPath)
		Write-Host "Updating $SSASdeploymentTargetsFileName..."

		[xml]$SSASCubeDeploymentTargetsFile = Get-Content "$SSASCubeDeploymentTargetsPath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Database = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Server = $deploymentTargetConfigFile.DeploymentTarget.Server
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.ConnectionString = $deploymentTargetConfigFile.DeploymentTarget.ConnectionString

		$SSASCubeDeploymentTargetsFile.Save("$SSASCubeDeploymentTargetsPath")

		Write-Host "$SSASdeploymentTargetsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentTarget failed: $_" -Error
	}
}