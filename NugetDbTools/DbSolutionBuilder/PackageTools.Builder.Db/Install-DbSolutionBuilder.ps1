ls * -Directory | % {
    rmdir "$($_.FullName)*" -Recurse -Force
}

if (-not (Test-Path .\NuGet)) {
    mkdir .\NuGet | Out-Null
}
nuget install DbSolutionBuilder -Source http://srv103octo01:808/NugetServer/nuget -OutputDirectory .\NuGet -ExcludeVersion


ls .\NuGet\**\* -Directory | % {
    if (-not (Test-Path ".\$($_.Name)")) {
        mkdir ".\$($_.Name)" | Out-Null
    }
    copy "$($_.FullName)\*" ".\$($_.Name)"
}

rmdir .\NuGet* -Recurse -Force
