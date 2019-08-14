$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }
cd $SolutionFolder

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1" -DisableNameChecking
}

$rtFolder = "$SolutionFolder\RegressionTests\Commands"
if (Test-Path $rtFolder\Execute_*_RegressionTests.cmd) {
	$sqlVars = @{}
	$dbServer = @{}
	$dbConn = @{}
	$profilePaths = Get-SqlProjects -SolutionPath $slnPath | % {
		$projPath = "$SolutionFolder\$($_.ProjectPath)"
		Find-PublishProfilePath -ProjectPath $projPath
	} | ? { Test-Path $_ }

	$profilePaths | % {
		[xml]$xml = gc $_
		$dbName = $xml.Project.PropertyGroup.TargetDatabaseName
		[Data.SqlClient.SqlConnectionStringBuilder]$csBuilder = New-Object Data.SqlClient.SqlConnectionStringBuilder($xml.Project.PropertyGroup.TargetConnectionString)
		$dbServer[$dbName] = $csBuilder.DataSource
		$csBuilder.Add('Initial Catalog', $dbName)
		$dbConn[$dbName] = $csBuilder
	}

	$profilePaths | % {
		$profilePath = $_
		[xml]$xml = gc $profilePath
		$xml.Project.ItemGroup.SqlCmdVariable | % {
			if ($_) {
				$sqlVars[$_.Include] = $_.Value
				if ($dbServer.ContainsKey($_.Value)) {
					$sqlVars["$($_.Include)_Server"] = $dbServer[$_.Value]
				}
			} else {
				Log "No SQL variables found in $([IO.Path]::GetFileName($profilePath))" -Warn
			}
		}
	}

	$sqlVars.Keys | % {
		$name = $_
		$value = $sqlVars[$name]
		[Environment]::SetEnvironmentVariable($name, $value, "Process")
	}

	$localSource = Get-NuGetLocalSource
	$packageContentFolder = "$SolutionFolder\PackageContent"
	Invoke-Trap -Command "nuget install TSQLUnit -Source '$localSource' -OutputDirectory '$packageContentFolder' -ExcludeVersion" -Message "Retrieving TSQLUnit failed" -Fatal
	$dacpacPath = "$SolutionFolder\PackageContent\TSQLUnit\Databases\TSQLUnit.dacpac"

	$sqlPackageCmd = Find-SqlPackagePath

	$dbConn.Keys | % {
		$dbName = $_
		$cs = $dbConn[$dbName].ToString()
		$db = "`/tcs:`"$cs`" `/p:CreateNewDatabase=False"
		Log "`"$sqlPackageCmd`" `/a:Publish `/sf:`"$dacpacPath`" $db"
		Invoke-Trap -Command "& `"$sqlPackageCmd`" `/a:Publish `/sf:`"$dacpacPath`" $db" -Message "Deploying TSQLUnit failed to $dbName" -Fatal
    }

	rd "$SolutionFolder\PackageContent" -Recurse
	
	@('Setup', 'Execute', 'Teardown') | % {
		ls "$rtFolder\$($_)_*_RegressionTests.cmd" | % {
            try {
                Invoke-Trap -Command "& `"$($_.FullName)`"" -Message "Regression test command failed: $($_.Name)" -Fatal
                if ($LASTEXITCODE) {
                    exit $LASTEXITCODE
                }
            } catch {
                exit 1
            }
        }
	}
} else {
	Log 'No regression tests found'
}