Get-ChildItem * -Directory | ForEach-Object {
    Remove-Item "$($_.FullName)*" -Recurse -Force
}

if (-not (Test-Path .\NuGet)) {
    mkdir .\NuGet | Out-Null
}
nuget install DbSolutionBuilder -Source https://pkgs.dev.azure.com/epsdev/_packaging/EpsNuGet/nuget/v3/index.json -OutputDirectory .\NuGet -ExcludeVersion


Get-ChildItem .\NuGet\**\* -Directory | ForEach-Object {
    if (-not (Test-Path ".\$($_.Name)")) {
        mkdir ".\$($_.Name)" | Out-Null
    }
    Copy-Item "$($_.FullName)\*" ".\$($_.Name)"
}

Remove-Item .\NuGet* -Recurse -Force
