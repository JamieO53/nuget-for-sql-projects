param (
	[string]$ProjectType = 'Db'
)
$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$BootstrapFolder = "$SolutionFolder\Bootstrap"
$package = 'DbSolutionBuilder'

if (Test-Path $BootstrapFolder) {
    del $BootstrapFolder\* -Recurse -Force
} else {
    mkdir $BootstrapFolder
}

$configPath = "$PSScriptRoot\PackageTools.root.config"
[xml]$config = Get-Content $configPath
$localSource = $config.tools.nuget.source

nuget install $package -Source $localSource -OutputDirectory $BootstrapFolder -ExcludeVersion

ls $BootstrapFolder -Directory | % {
    ls $_.FullName -Directory | % {
        if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
            mkdir "$SolutionFolder\$($_.Name)"
        }
		copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
    }
}

if (Test-Path "$SolutionFolder\PackageTools\Package.nuspec.txt") {
	if (Test-Path "$SolutionFolder\PackageTools\Package.nuspec") {
		Remove-Item "$SolutionFolder\PackageTools\Package.nuspec"
	}
	Rename-Item "$SolutionFolder\PackageTools\Package.nuspec.txt" 'Package.nuspec'
}

del $BootstrapFolder -Include '*' -Recurse