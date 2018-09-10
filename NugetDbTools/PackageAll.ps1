if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module .\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1
}
if (-not (Test-IsRunningBuildAgent) -and -not (Test-PathIsCommitted)) {
	Write-Error 'Commit changes before publishing the projects to NuGet'
	exit 1
}
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
$order.PackageOrder | % {
	$sourceIsUpdated[$_] = $nugetVersion[$_] -ne $sourceVersion[$_]
}
$order.PackageOrder | % {
	if ($sourceIsUpdated[$_]) {
		$name = $_
		$order.PackageOrder | ? { -not $sourceIsUpdated[$_] } | % {
			$projectFolder = "$solutionFolder\$_"
			$buildConfigPath = "$projectFolder\BuildConfig.ps1"
			$buildConfig = Import-PowerShellDataFile $buildConfigPath
			$sourceIsUpdated[$name] = ($buildConfig.Dependencies -contains $name)
		}
	}
}

try {
	$order.PackageOrder | ? { $sourceIsUpdated[$_] } | % {
		pushd "$solutionFolder\$_"
		powershell.exe -command '.\Package.ps1; exit $LASTEXITCODE'
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