$SolutionFolder = Split-Path -Path $MyInvocation.MyCommand.Path
ls $SolutionFolder -Directory | % {
    $folder = $_.FullName
    if (Test-Path "$folder\Build.ps1") {
        & "$folder\Build.ps1"
    }
}