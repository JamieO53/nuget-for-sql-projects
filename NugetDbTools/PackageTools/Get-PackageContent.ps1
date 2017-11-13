$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }
$packageContentFolder = "$SolutionFolder\PackageContent"

if (Test-Path $packageContentFolder) {
    del $packageContentFolder\* -Recurse -Force
} else {
    mkdir $packageContentFolder | Out-Null
}

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"

Get-SolutionPackages -SolutionPath $slnPath -ContentFolder $packageContentFolder

ls $packageContentFolder -Directory | % {
	ls $_.FullName -Directory | % {
		if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
			mkdir "$SolutionFolder\$($_.Name)"
		}
		copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
	}
}

del $packageContentFolder -Include '*' -Recurse