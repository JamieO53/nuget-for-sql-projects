$SolutionFolder = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if (-not (Get-Module NugetSharedPacker)) {
	Import-Module "$SolutionFolder\PowerShell\NugetShared.psd1"
	Import-Module "$SolutionFolder\PowerShell\NugetSharedPacker.psd1"
}

Get-SolutionContent -SolutionPath $slnPath

$reference = Get-SolutionDependencies -SolutionPath $slnPath
$reference.Keys | sort | % {
	$package = $_
	$version = $reference[$package]
	if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
		Set-NuGetDependencyVersion -SolutionPath $slnPath -Dependency $package -Version $version
	}
}
