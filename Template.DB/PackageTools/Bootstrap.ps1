$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
$BootstrapFolder = "$SolutionFolder\PackageTools"

if (Test-Path $BootstrapFolder) {
    del $BootstrapFolder\* -Recurse -Force
} else {
    mkdir $BootstrapFolder
}

$configPath = "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
[xml]$config = Get-Content $configPath
$localSource = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }

nuget install NuGetDbPacker -Source $localSource -OutputDirectory $BootstrapFolder

ls $BootstrapFolder -Directory | % {
    ls $_.FullName -Directory | % {
        if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
            mkdir "$SolutionFolder\$($_.Name)"
        }
        copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
    }
}

del $BootstrapFolder -Include '*' -Recurse