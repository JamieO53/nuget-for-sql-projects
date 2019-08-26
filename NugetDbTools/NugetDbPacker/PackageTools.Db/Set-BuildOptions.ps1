$nugetConfigDir = "$PSScriptRoot\..\JamieO53\NugetDbTools"
$nugetConfigPath = "$nugetConfigDir\NugetDbTools.config"

$configText = @"
<?xml version=`"1.0`"?>
<configuration>
    <nugetLocalServer>
        <add key="ApiKey" value="ApiKey" />
		<add key=`"ContentFolder`" value=`"Runtime`"/>
        <add key=`"Source`" value=`"https://pkgs.dev.azure.com/epsdev/_packaging/EpsNuGet/nuget/v3/index.json`"/>
        <add key=`"PushTimeout`" value=`"900`"/> <!-- seconds -->
    </nugetLocalServer>
</configuration>
"@
if (-not (Test-Path $nugetConfigDir)) {
	mkdir $nugetConfigDir
}
if (-not (Test-Path $nugetConfigPath)) {
	$configText | Set-Content $nugetConfigPath -Encoding UTF8 -Force
	Write-Host "Set up $nugetConfigPath"
}

sqllocaldb create ecentric