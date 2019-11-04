[string]$Global:ConfigPath = "$PSScriptRoot\PackageTools\PackageTools.root.config"
if (Get-Module NuGetSharedPacker -All) {
	Remove-Module NuGet*,*Extension
}
Import-Module "$PSScriptRoot\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1" -Global -DisableNameChecking

[string]$solutionFolder = $PSScriptRoot
$packageOrder = Import-PowerShellDataFile "$solutionFolder\PackageSequence.psd1"
$order = $packageOrder.PackageOrder
$versionParts = $packageOrder.Version
[string]$oldLabel = Get-Label -Prefix $versionParts.Prefix
[string]$newLabel = "$($versionParts.prefix)$($versionParts.major).$($versionParts.minor).$(Get-RevisionCount -Path $solutionFolder)"
[string]$branch = Get-Branch $solutionFolder

$nugetVersion = @{}
$order | ForEach-Object {
	$version = (Get-NuGetPackageVersion -PackageName $_)
	if ($branch) {
		$branchVersion = (Get-NuGetPackageVersion -PackageName $_ -Branch $branch)
		if ($branchVersion) {
			$nugetVersion[$_] = $branchVersion
		} else {
			$nugetVersion[$_] = $version
		}
	} else {
		$nugetVersion[$_] = $version
	}
}
$sourceVersion = @{}
$sourceCommits = @{}
$order | ForEach-Object {
	$projectFolder = "$solutionFolder\$_"
	$nuspecPath = "$projectFolder\Package.nuspec"
	$sourceVersion[$_] = (Measure-ProjectVersion -Path $nuspecPath -ProjectFolder $projectFolder)
	$sourceCommits[$_] = (Get-RevisionCountAfterLabel -Path $projectFolder -Label $oldLabel) -gt 0
}
$sourceIsUpdated = @{}
$order |  Where-Object {
	$nugetVersion[$_] -ne $sourceVersion[$_] -or $sourceCommits
} | Where-Object {
	-not $sourceIsUpdated[$_]
} | ForEach-Object {
	$sourceIsUpdated[$_] = $true
}
$upVersion = @{}
$order | ForEach-Object {
	$upVersion[$_] = $false
}
$order | ForEach-Object {
	if ($sourceIsUpdated[$_]) {
		$projectFolder = "$solutionFolder\$_"
		$buildConfigPath = "$projectFolder\BuildConfig.psd1"
		$buildConfig = Import-PowerShellDataFile $buildConfigPath
		$buildConfig.Dependents | Where-Object { -not $sourceIsUpdated[$_] } | ForEach-Object {
			$sourceIsUpdated[$_] = $true
			$upVersion[$_] = $true
		}
	}
}

try {
	$order | Where-Object { $sourceIsUpdated[$_] } | ForEach-Object {
		Push-Location "$solutionFolder\$_"
		.\Package.ps1 -UpVersion $upVersion[$_]
		Pop-Location
		if ($LASTEXITCODE) {
			throw "Package of $_ failed"
		}
	}
	if (-not $branch) {
		Set-Label $newLabel
	}
} catch {
	Write-Host $_.Exception.Message -ForegroundColor Red
	exit 1
} finally {
	Pop-Location
}
