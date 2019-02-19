param (
    [string]$path='.'
)
$nugetSource = '<<<<URI of local NuGet server>>>>'
$nugetPushSource = '<<<<URI of local NuGet server for pushed packages (optional)>>>>'
$nugetApiKey = '<<<<ApiKey of local NuGet server>>>>'
$defaultLocation = '<<<<Default solution location on developer PC>>>>'
$sampleSolutionName = '<<<<An example solution name>>>>'
$sampleDatabaseName = '<<<<An example database name>>>>'
$sampleDependencyId = '<<<<An example database reference in the form solutionName.databaseName>>>>'

function Set-NuGetConfig {
    $nugetConfigDir = "$env:APPDATA\JamieO53\NugetDbTools"
    $nugetConfigPath = "$nugetConfigDir\NugetDbTools.config"
    $configText = @"
<?xml version=`"1.0`"?>
<configuration>
    <nugetLocalServer>
        <add key=`"ApiKey`" value=`"$nugetApiKey`"/>
        <add key=`"Source`" value=`"$nugetSource`"/>
        <add key=`"PushSource`" value=`"$nugetPushSource`"/>
    </nugetLocalServer>
</configuration>
"@

    if (-not (Test-Path $nugetConfigDir)) {
        mkdir $nugetConfigDir | Out-Null
    }
    if (Test-Path $nugetConfigPath) {
        [xml]$nugetConfig = Get-Content $nugetConfigPath
        $nugetConfig.configuration.nugetLocalServer.add | % {
            $item = $_
            if ($item.key -eq 'Source') {
                $item.value = $nugetSource
            } elseif ($item.key -eq 'ApiKey') {
                $item.value = $nugetApiKey
            }
        }
        $nugetConfig.Save($nugetConfigPath)
    } else {
        $configText | Set-Content $nugetConfigPath -Encoding UTF8
    }
}

function Get-DbSolutionBuilder {
    $bootstrapFolder = "$Path\Bootstrap"
    if (Test-Path $BootstrapFolder) {
        del $BootstrapFolder\* -Recurse -Force
    } else {
        mkdir $BootstrapFolder | Out-Null
    }

    nuget install DbSolutionBuilder -Source $nugetSource -OutputDirectory $bootstrapFolder -ExcludeVersion

    ls $BootstrapFolder -Directory | % {
        ls $_.FullName -Directory | % {
            if (-not (Test-Path "$Path\$($_.Name)")) {
                mkdir "$Path\$($_.Name)" | Out-Null
            }
            copy "$($_.FullName)\*" "$Path\$($_.Name)"
        }
    }

    del $BootstrapFolder -Include '*' -Recurse

    'New-CiDbProject.ps1' | % {
        $filePath = "$Path\PackageTools\$_"
        if (Test-Path $filePath) {
            copy $filePath $Path
        }
    }
	$dbTemplatePath = "$Path\DbTemplate.xml"
	if (-not (Test-Path $dbTemplatePath)) {
		$dbTemplateText = @"
<dbSolution>
	<parameters>
		<location>$defaultLocation</location>
		<name>$sampleSolutionName</name>
	</parameters>
	<databases>
        <database dbName=`"$sampleDatabaseName`"/>
	</databases>
	<dependencies>
        <dependency id=`"$sampleDependencyId`"/>
	</dependencies>
</dbSolution>
"@
	$dbTemplateText | Set-Content $dbTemplatePath -Encoding UTF8
	}
}

Set-NuGetConfig
Get-DbSolutionBuilder