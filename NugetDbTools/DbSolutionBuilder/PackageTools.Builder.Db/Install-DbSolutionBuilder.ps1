Get-ChildItem * -Directory | ForEach-Object {
    Remove-Item "$($_.FullName)*" -Recurse -Force
}

if (-not (Test-Path .\NuGet)) {
    mkdir .\NuGet | Out-Null
}
$Global:ConfigPath = "$PSScriptRoot\PackageTools.root.config"
[xml]$config = Get-Content $Global:ConfigPath
$localSource = $config.tools.nuget.source
nuget install DbSolutionBuilder -Source $localSource -OutputDirectory .\NuGet -ExcludeVersion

Get-ChildItem .\NuGet\**\* -Directory | ForEach-Object {
    if (-not (Test-Path ".\$($_.Name)")) {
        mkdir ".\$($_.Name)" | Out-Null
    }
    Copy-Item "$($_.FullName)\*" ".\$($_.Name)"
}

Remove-Item .\NuGet* -Recurse -Force
