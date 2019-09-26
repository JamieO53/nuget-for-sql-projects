param(
	[string]$databaseName = ''
)
$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }
cd $SolutionFolder

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1" -Global -DisableNameChecking
}

$rtFolder = "$SolutionFolder\RegressionTests\Commands"
if (Test-Path $rtFolder\Execute_*_RegressionTests.cmd) {
	$sqlVars = @{}
	$dbServer = @{}
	$dbConn = @{}
	$profilePaths = Get-SqlProjects -SolutionPath $slnPath | ? { -not $databaseName -or ($databaseName -eq $_.Project) } | % {
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

	
	$packageContentFolder = "$SolutionFolder\PackageContent"
	if (-not (Test-Path $packageContentFolder\tsqlunit)) {
		mkdir $packageContentFolder | Out-Null
		pushd $packageContentFolder
		git clone https://github.com/aevdokimenko/tsqlunit.git
		$hack = @"
CREATE PROCEDURE dbo.tsu_AssertEquals
	@Expected SQL_VARIANT,
	@Actual SQL_VARIANT,
	@Message NVARCHAR(MAX) = ''
AS
BEGIN
    IF ((@Expected = @Actual) OR (@Actual IS NULL AND @Expected IS NULL))
      RETURN 0;

    DECLARE @Msg NVARCHAR(MAX);
    SELECT @Msg = 'Expected: <' + ISNULL(CAST(@Expected AS NVARCHAR(MAX)), 'NULL') + 
                  '> Actual: <' + ISNULL(CAST(@Actual AS NVARCHAR(MAX)), 'NULL') + '>';
    IF((COALESCE(@Message,'') <> '') AND (@Message NOT LIKE '% ')) SET @Message = @Message + ': ';
    SET @Message = @Message + @Msg
    EXEC tsu_failure @Message
END;	
"@
		$hack | Out-File $packageContentFolder\hack.sql -Encoding utf8
		popd
	}

	Import-Module SqlServer -DisableNameChecking -Global

	$dbConn.Keys | % {
		$dbName = $_
		$cs = $dbConn[$dbName].ToString()
		if (-not (Invoke-Sqlcmd "select name from sys.tables where name = 'tsuActiveTest'" -ConnectionString "$cs")) {
			$cmd = "Invoke-Sqlcmd -InputFile `"$packageContentFolder\tsqlunit\tsqlunit.sql`" -ConnectionString `"$cs`""
			Log $cmd
			Invoke-Trap `
				-Command $cmd `
				-Message "Adding TSqlUnit to $dbName failed"
			$cmd = "Invoke-Sqlcmd -InputFile `"$packageContentFolder\hack.sql`" -ConnectionString `"$cs`""
			Log $cmd
			Invoke-Trap `
				-Command $cmd `
				-Message "Hacking TSqlUnit on $dbName failed"
			}
    }

	rd "$SolutionFolder\PackageContent" -Recurse -Force
	
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