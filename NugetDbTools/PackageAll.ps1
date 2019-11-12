if (Get-Module NuGetSharedPacker -All) {
	Remove-Module NuGet*,*Extension
}
[string]$Global:ConfigPath = (Get-Item "$PSScriptRoot\PackageTools\PackageTools.root.config").FullName
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
	$sourceVersion[$_] = (Measure-ProjectVersion -Path $nuspecPath -ProjectFolder $projectFolder -OldVersion $nugetVersion[$_])
	$sourceCommits[$_] = $sourceVersion[$_] -ne $nugetVersion[$_]
}
$sourceIsUpdated = @{}
$order |  Where-Object {
	$nugetVersion[$_] -ne $sourceVersion[$_] -or $sourceCommits[$_]
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

$order | ForEach-Object { New-Object -TypeName psobject -Property @{
	Module=$_
	NugetVersion=$nugetVersion[$_]
	SourceVersion=$sourceVersion[$_]
	SourceCommits=$sourceCommits[$_]
	SourceIsUpdated=$sourceIsUpdated[$_]
	UpVersion=$upVersion[$_]
}
} | Format-Table -Property Module,NugetVersion,SourceVersion,SourceCommits,SourceIsUpdated,UpVersion

try {
	$order | Where-Object { $sourceIsUpdated[$_] } | ForEach-Object {
		Push-Location "$solutionFolder\$_"
		.\Package.ps1 -UpVersion $upVersion[$_]
		Pop-Location
		if ($LASTEXITCODE) {
			throw "Package of $_ failed"
		}
	}
	if (-not $branch -and $newLabel -ne $oldLabel) {
		Set-Label $newLabel
	}
} catch {
	Write-Host $_.Exception.Message -ForegroundColor Red
	exit 1
} finally {
	Pop-Location
}
