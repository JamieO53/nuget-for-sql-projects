function Update-SSASCubeDeploymentOptions {
	param (
		[string]$SSASCubeDeploymentOptionsPath,
		[string]$DeploymentOptionsConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentOptionsPath)) {
			Write-Host "$SSASCubeDeploymentOptionsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentOptionsConfigPath)) {
			Write-Host "$DeploymentOptionsConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentOptionsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentOptionsPath)
		Write-Host "Updating $SSASdeploymentOptionsFileName..."

		[xml]$SSASCubeDeploymentOptionsFile = Get-Content "$SSASCubeDeploymentOptionsPath"
		[xml]$deploymentOptionsConfigFile = Get-Content "$DeploymentOptionsConfigPath"
		
		$SSASCubeDeploymentOptions = $SSASCubeDeploymentOptionsFile.DeploymentOptions.ChildNodes
		$deploymentOptions = $deploymentOptionsConfigFile.DeploymentOptions.ChildNodes

		foreach ($deploymentOption in $deploymentOptions) {
			$SSASCubeDeploymentOption = $SSASCubeDeploymentOptions | Where-Object { $_.Name -eq $deploymentOption.Name }

			if ($null -ne $SSASCubeDeploymentOption) {
				$SSASCubeDeploymentOption.InnerText = $deploymentOption.InnerText
			}
		}

		$SSASCubeDeploymentOptionsFile.Save("$SSASCubeDeploymentOptionsPath")

		Write-Host "$SSASdeploymentOptionsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentOptions failed: $_" -Error
	}
}