$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
$BootstrapFolder = "$SolutionFolder\Bootstrap"

if (Test-Path $BootstrapFolder) {
    del $SolutionFolder\* -Recurse -Force
} else {
    mkdir $BootstrapFolder
}

nuget install NuGetDbPacker -Source 'http://srv103octo01:808/NugetServer/nuget' -OutputDirectory $BootstrapFolder

ls $BootstrapFolder -Directory | % {
    ls $_.FullName -Directory | % {
        if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
            mkdir "$SolutionFolder\$($_.Name)"
        }
        copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
    }
}

del $BootstrapFolder -Include '*' -Recurse