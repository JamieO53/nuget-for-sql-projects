param (
	[string]$ProjectType = 'Db'
)
$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$BootstrapFolder = "$SolutionFolder\Bootstrap"
$package = 'DbSolutionBuilder'

if (Test-Path $BootstrapFolder) {
    Remove-Item $BootstrapFolder\* -Recurse -Force
} else {
    mkdir $BootstrapFolder
}

$Global:ConfigPath = "$PSScriptRoot\PackageTools.root.config"
[xml]$config = Get-Content $configPath
$localSource = $config.tools.nuget\source

nuget install $package -Source $localSource -OutputDirectory $BootstrapFolder -ExcludeVersion

Get-ChildItem $BootstrapFolder -Directory | ForEach-Object {
    Get-ChildItem $_.FullName -Directory | ForEach-Object {
        if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
            mkdir "$SolutionFolder\$($_.Name)"
        }
		Copy-Item "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
    }
}

if (Test-Path "$SolutionFolder\PackageTools\Package.nuspec.txt") {
	if (Test-Path "$SolutionFolder\PackageTools\Package.nuspec") {
		Remove-Item "$SolutionFolder\PackageTools\Package.nuspec"
	}
	Rename-Item "$SolutionFolder\PackageTools\Package.nuspec.txt" 'Package.nuspec'
}

Remove-Item $BootstrapFolder -Include '*' -Recurse
