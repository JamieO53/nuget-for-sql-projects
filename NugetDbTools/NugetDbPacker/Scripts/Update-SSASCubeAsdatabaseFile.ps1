function Update-SSASCubeAsdatabaseFile {
	param (
		[string]$SSASCubeAsdatabasePath,
		[string]$DeploymentTargetConfigPath
	)
	
	try {
		if ([string]::IsNullOrEmpty($SSASCubeAsdatabasePath)) {
			Write-Host "$SSASCubeAsdatabasePath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeAsdatabaseFileName = [IO.Path]::GetFileName($SSASCubeAsdatabasePath)
		Write-Host "Updating $SSASCubeAsdatabaseFileName..."

		[xml]$SSASCubeAsdatabaseFile = Get-Content "$SSASCubeAsdatabasePath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeAsdatabaseFile.Database.ID = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeAsdatabaseFile.Database.Name = $deploymentTargetConfigFile.DeploymentTarget.Database

		$SSASCubeAsdatabaseFile.Save("$SSASCubeAsdatabasePath")

		Write-Host "$SSASCubeAsdatabaseFileName datasource updated..."
	} catch {
		Log "Update-SSASCubeAsdatabaseFile failed: $_" -Error
	}
}