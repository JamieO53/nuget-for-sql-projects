[string]$Global:ConfigPath = "$PSScriptRoot\PackageTools\PackageTools.root.config"
if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module "$PSScriptRoot\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1" -Global
}
# if (-not (Test-IsRunningBuildAgent) -and -not (Test-PathIsCommitted)) {
# 	Write-Host 'Commit changes before publishing the projects to NuGet' -ForegroundColor Red
# 	exit 1
# }
Remove-Variable * -ErrorAction SilentlyContinue
[string]$Global:ConfigPath = "$PSScriptRoot\PackageTools\PackageTools.root.config"
$solutionFolder = $PSScriptRoot
$order = Import-PowerShellDataFile "$solutionFolder\PackageSequence.psd1"
$nugetVersion = @{}
$order.PackageOrder | ForEach-Object {
	$nugetVersion[$_] = (Get-NuGetPackageVersion -PackageName $_)
}
$sourceVersion = @{}
$order.PackageOrder | ForEach-Object {
	$projectFolder = "$solutionFolder\$_"
	$nuspecPath = "$projectFolder\Package.nuspec"
	$sourceVersion[$_] = (Measure-ProjectVersion -Path $nuspecPath -ProjectFolder $projectFolder)
}
$sourceIsUpdated = @{}
$order.PackageOrder |  Where-Object {
	$nugetVersion[$_] -ne $sourceVersion[$_]
} | Where-Object {
	-not $sourceIsUpdated[$_]
} | ForEach-Object {
	$sourceIsUpdated[$_] = $true
}
$upVersion = @{}
$order.PackageOrder | ForEach-Object {
	$upVersion[$_] = $false
}
$order.PackageOrder | ForEach-Object {
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

# try {
# 	$order.PackageOrder | Where-Object { $sourceIsUpdated[$_] } | ForEach-Object {
# 		Push-Location "$solutionFolder\$_"
# 		#powershell.exe -command '.\Package.ps1; exit $LASTEXITCODE'
# 		.\Package.ps1 -UpVersion $upVersion[$_]
# 		Pop-Location
# 		if ($LASTEXITCODE) {
# 			throw "Package of $_ failed"
# 		}
# 	}
# } catch {
# 	Write-Host $_.Exception.Message -ForegroundColor Red
# 	exit 1
# } finally {
# 	Pop-Location
# }
# Remove-Variable * -ErrorAction SilentlyContinue
$upVersion