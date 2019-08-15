[string]$deployChannel = $env:DeployChannel

if (-not $deployChannel) {
	Write-Host "DeployChannel environment variable not set" -ForegroundColor Red
	exit 1
}

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}

if (Test-Path "$PSScriptRoot\PowerShell\NugetDbPacker.psd1") {
	Import-Module "$PSScriptRoot\PowerShell\NugetDbPacker.psd1"
} elseif (Test-Path "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1") {
	Import-Module "$PSScriptRoot\..\PowerShell\NugetDbPacker.psd1"
} else {
	Write-Host "NugetDbPacker module could not be located" -ForegroundColor Red
	exit 1
}

if (Test-Path "$PSScriptRoot\..\Release\PackageDeploy.config") {
	$deployRoot = "$PSScriptRoot\..\Release"
	[xml]$config = gc "$deployRoot\PackageDeploy.config"
} elseif (Test-Path "$PSScriptRoot\..\PackageDeploy.config") {
	$deployRoot = "$PSScriptRoot\.."
	[xml]$config = gc "$deployRoot\PackageDeploy.config"
} elseif (Test-Path "$PSScriptRoot\PackageDeploy.config") {
	$deployRoot = $PSScriptRoot
	[xml]$config = gc "$deployRoot\PackageDeploy.config"
} else {
	Write-Host "PackageDeploy.config file could not be located" -ForegroundColor Red
	exit 1
}

$configPath = "$deployRoot\$($config.package.paths.configPath)\$deployChannel\SSAS\Databases"
$dbPath = "$deployRoot\$($config.package.paths.dbPath)"
$ssasPath = "$deployRoot\$($config.package.paths.ssasPath)"
$ssasDBPath = "$ssasPath\Databases"

$config.package.deployChannels.deployChannel | ? { $_.name -eq $deployChannel } | % {
	$targetServerName = $_.targetServerName
}

if (-not $targetServerName) {
	Write-Host "The target server name for Deploy Channel $deployChannel is not defined" -ForegroundColor Red
	exit 1
}

$config.package.databases.database | % {
	$dbName = $_.name
	$dacpacPath = "$dbPath\$dbName.dacpac"
	if (-not (Test-Path $dacpacPath)) {
		Write-Host "$dacpacPath does not exist" -ForegroundColor Red
		exit 1
	}
	$profilePath = Find-PublishProfilePath $dacpacPath $deployChannel
	if (-not $profilePath) {
		Write-Host "Unable to identify the publish profile for $dbName" -ForegroundColor Red
		exit 1
	}
	[string]$params = $_.parameters
	if ($params) {
		$parameters = iex $params
	} else {
		$parameters = ''
	}
	try {
		Write-Host "Deploying $dbName using $(Split-Path $profilePath -Leaf)" -ForegroundColor Yellow
		if ($parameters) {
			Write-Host "... with parameters $parameters" -ForegroundColor Yellow
			Publish-ProjectDatabase $dacpacPath $profilePath $parameters
		} else {
			Publish-ProjectDatabase $dacpacPath $profilePath
		}
	} catch {
		Log "Deploying $dbName failed: $_" -Error
		Log $_ -Error
		exit 1
	}
}

$config.package.cubes.cube | % {
	$cubeName = $_.name
	$cubeFolder = $_.folder
	$databaseName = $_.databaseName
	$deploymentError = $_.deploymentError
	try {
		Push-Location "$ssasPath\DeploymentUtility\"

		Publish-SSASCubeDatabase `
			-CubeFolder "$ssasDBPath\$cubeFolder" `
			-CubeName $cubeName `
			-ConfigSharedFolder "$configPath\Shared" `
			-ConfigFolder "$configPath\$cubeFolder" `
			-DatabaseName $databaseName `
			-DeploymentError $deploymentError
	} catch {
		Log "SSAS DeploymentUtility failed: $_" -Error
		Log $_ -Error
		exit 1
	} finally {
		Pop-Location
	}
}