if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module .\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1
}
$order = Import-PowerShellDataFile .\PackageSequence.psd1
$nugetVersion = @{}
$order.PackageOrder | % {
	$nugetVersion[$_] = (Get-NuGetPackageVersion -PackageName $_)
}
$sourceVersion = @{}
$order.PackageOrder | % {
	$projectFolder = ".\$_"
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
		$order.PackageOrder | ? { -not $sourceIsUpdated[$_] } % {
			$projectFolder = ".\$_"
			$buildConfigPath = "$projectFolder\BuildConfig.ps1"
			$buildConfig = Import-PowerShellDataFile $buildConfigPath
			$sourceIsUpdated[$_] = ($buildConfig.Dependencies -contains $name)
		}
	}
}

$order.PackageOrder | % {
	$package = $_
	$nuspecPath = ".\$_\Package.nuspec"
	[xml]$nuspec = gc $nuspecPath
	$version = Set-NuspecVersion -Path $nuspecPath -ProjectFolder ".\$_"
	$update = $version -ne (Get-NuspecProperty 'version')
	if ($update) {
		$order.PackageOrder | % {
			$dependant = $_
			$depNuspecPath = ".\$_\Package.nuspec"
		}
	}
}