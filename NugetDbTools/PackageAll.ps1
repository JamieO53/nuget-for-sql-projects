if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module .\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1
}
# if (-not (Test-IsRunningBuildAgent) -and -not (Test-PathIsCommitted)) {
# 	Write-Host 'Commit changes before publishing the projects to NuGet' -ForegroundColor Red
# 	exit 1
# }
Remove-Variable * -ErrorAction SilentlyContinue
$solutionFolder = (Get-Location).Path
$order = Import-PowerShellDataFile "$solutionFolder\PackageSequence.psd1"
$nugetVersion = @{}
$order.PackageOrder | % {
	$nugetVersion[$_] = (Get-NuGetPackageVersion -PackageName $_)
}
$sourceVersion = @{}
$order.PackageOrder | % {
	$projectFolder = "$solutionFolder\$_"
	$nuspecPath = "$projectFolder\Package.nuspec"
	$sourceVersion[$_] = (Measure-ProjectVersion -Path $nuspecPath -ProjectFolder $projectFolder)
}
$sourceIsUpdated = @{}
$order.PackageOrder |  ? {
	$nugetVersion[$_] -ne $sourceVersion[$_]
} | ? {
	-not $sourceIsUpdated[$_]
} | % {
	$sourceIsUpdated[$_] = $true
}
$order.PackageOrder | % {
	if ($sourceIsUpdated[$_]) {
		$order.PackageOrder | % {
			$projectFolder = "$solutionFolder\$_"
			$buildConfigPath = "$projectFolder\BuildConfig.psd1"
			$buildConfig = Import-PowerShellDataFile $buildConfigPath
			$buildConfig.Dependents | % {
				$sourceIsUpdated[$_] = $true
			}
		}
	}
}

try {
	$order.PackageOrder | ? { $sourceIsUpdated[$_] } | % {
		pushd "$solutionFolder\$_"
		#powershell.exe -command '.\Package.ps1; exit $LASTEXITCODE'
		.\Package.ps1
		popd
		if ($LASTEXITCODE) {
			throw "Package of $_ failed"
		}
	}
} catch {
	Write-Host $_.Exception.Message -ForegroundColor Red
	exit 1
} finally {
	popd
}