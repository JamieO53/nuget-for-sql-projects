$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetDbPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"
}

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
    [xml]$xml = gc $_
    $xml.Project.ItemGroup.SqlCmdVariable | % {
        $sqlVars[$_.Include] = $_.Value
        if ($dbServer.ContainsKey($_.Value)) {
            $sqlVars["$($_.Include)_Server"] = $dbServer[$_.Value]
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
iex "nuget install TSQLUnit -Source '$localSource' -OutputDirectory '$packageContentFolder' -ExcludeVersion"
$dacpacPath = "$SolutionFolder\PackageContent\TSQLUnit\Databases\TSQLUnit.dacpac"

$sqlPackageCmd = Find-SqlPackagePath

$dbConn.Keys | % {
    $dbName = $_
    $cs = $dbConn[$dbName].ToString()
    $db = "`/tcs:`"$cs`" `/p:CreateNewDatabase=False"
    Log "`"$sqlPackageCmd`" `/a:Publish `/sf:`"$dacpacPath`" $db"
	#Invoke-Trap -Command "& `"$sqlPackageCmd`" `/a:Publish `/sf:`"$dacpacPath`" $db" -Message "Deploying TSQLUnit failed to $db" -Fatal
}

