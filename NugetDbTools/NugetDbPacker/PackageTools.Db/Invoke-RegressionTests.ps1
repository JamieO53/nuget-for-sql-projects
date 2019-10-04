param(
	[string]$databaseName = ''
)
$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=Get-ChildItem $SolutionFolder\*.sln | Where-Object { $_ } | ForEach-Object { $_.FullName }
Set-Location $SolutionFolder

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1" -Global -DisableNameChecking
}

$rtFolder = "$SolutionFolder\RegressionTests\Commands"
if (Test-Path $rtFolder\Execute_*_RegressionTests.cmd) {
	$sqlVars = @{}
	$dbServer = @{}
	$dbConn = @{}
	$profilePaths = Get-SqlProjects -SolutionPath $slnPath | Where-Object { -not $databaseName -or ($databaseName -eq $_.Project) } | ForEach-Object {
		$projPath = "$SolutionFolder\$($_.ProjectPath)"
		Find-PublishProfilePath -ProjectPath $projPath
	} | Where-Object { Test-Path $_ }

	$profilePaths | ForEach-Object {
		[xml]$xml = Get-Content $_
		$dbName = $xml.Project.PropertyGroup.TargetDatabaseName
		[Data.SqlClient.SqlConnectionStringBuilder]$csBuilder = New-Object Data.SqlClient.SqlConnectionStringBuilder($xml.Project.PropertyGroup.TargetConnectionString)
		$dbServer[$dbName] = $csBuilder.DataSource
		$csBuilder.Add('Initial Catalog', $dbName)
		$dbConn[$dbName] = $csBuilder
	}

	$profilePaths | ForEach-Object {
		$profilePath = $_
		[xml]$xml = Get-Content $profilePath
		$xml.Project.ItemGroup.SqlCmdVariable | ForEach-Object {
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

	$sqlVars.Keys | ForEach-Object {
		$name = $_
		$value = $sqlVars[$name]
		[Environment]::SetEnvironmentVariable($name, $value, "Process")
	}

	
	$packageContentFolder = "$SolutionFolder\PackageContent"
	if (-not (Test-Path $packageContentFolder\tsqlunit)) {
		mkdir $packageContentFolder | Out-Null
		Push-Location $packageContentFolder
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
    Select-Object @Msg = 'Expected: <' + ISNULL(CAST(@Expected AS NVARCHAR(MAX)), 'NULL') + 
                  '> Actual: <' + ISNULL(CAST(@Actual AS NVARCHAR(MAX)), 'NULL') + '>';
    IF((COALESCE(@Message,'') <> '') AND (@Message NOT LIKE '% ')) SET @Message = @Message + ': ';
    SET @Message = @Message + @Msg
    EXEC tsu_failure @Message
END;	
"@
		$hack | Out-File $packageContentFolder\hack.sql -Encoding utf8
		Pop-Location
	}

	Import-Module SqlServer -DisableNameChecking -Global

	$dbConn.Keys | ForEach-Object {
		$dbName = $_
		$cs = $dbConn[$dbName].ToString()
		if (-not (Invoke-Sqlcmd "Select name from sys.tables where name = 'tsuActiveTest'" -ConnectionString "$cs")) {
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

	Remove-Item "$SolutionFolder\PackageContent" -Recurse -Force
	
	@('Setup', 'Execute', 'Teardown') | ForEach-Object {
		Get-ChildItem "$rtFolder\$($_)_*_RegressionTests.cmd" | ForEach-Object {
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