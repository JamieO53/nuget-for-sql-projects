param (
    [string]$path='.'
)
$nugetSource = '<<<<URI of local NuGet server>>>>'
$nugetPushSource = '<<<<URI of local NuGet server for pushed packages (optional)>>>>'
$nugetApiKey = '<<<<ApiKey of local NuGet server>>>>'
$contentFolder = '<<<<Name of the additional content folder>>>>'
$defaultLocation = '<<<<Default solution location on developer PC>>>>'
$sampleSolutionName = '<<<<An example solution name>>>>'
$sampleDatabaseName = '<<<<An example database name>>>>'
$sampleDependencyId = '<<<<An example database reference in the form solutionName.databaseName>>>>'

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

Get-DbSolutionBuilder