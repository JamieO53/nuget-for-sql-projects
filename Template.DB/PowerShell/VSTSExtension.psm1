
function Test-IsRunningBuildAgent {
	if ($env:USERNAME -eq 'VssAdministrator') {
		$true
	} else {
		$buildAgent = (
			get-service | ? {
				($_.Status -eq 'Running') -and ($_.Name -like 'vstsagent.*')
			} | % {
				$_.Name
			}
		)
		-not ([string]::IsNullOrEmpty($buildAgent))
	}
}

if (Test-IsRunningBuildAgent) {
	$configPath = "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
	$configFolder = Split-Path $configPath
	if (-not (Test-Path $configPath)) {
		$config = @"
`<`?xml version=`"1.0`"`?`>
`<configuration`>
	`<nugetLocalServer`>
		`<add key=`"ApiKey`" value=`"AzureDevOps`"`/`>
		`<add key=`"Source`" value=`"$env:NuGetSource`"`/`>
	`<`/nugetLocalServer`>
`<`/configuration`>
"@
		if (-not (Test-Path $configFolder)) {
			mkdir $configFolder | Out-Null
		}
		$config | Out-File -FilePath $configPath -Encoding utf8
	}
}


