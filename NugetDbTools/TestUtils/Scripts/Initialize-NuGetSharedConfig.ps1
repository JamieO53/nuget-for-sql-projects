function Initialize-NuGetSharedConfig ($rootPath, $config) {
	$solutionPath = "TestDrive:\solution"
	$packageToolsPath = "$solutionPath\PackageTools"
	$powerShellPath = "$solutionPath\PowerShell"
	$toolConfigPath = "$packageToolsPath\PackageTools.root.config"
	if (Get-Module NugetShared -All) {
		Remove-Module NugetShared
	}
	if (Test-Path $solutionPath) {
		rmdir "$solutionPath*" -Force -Recurse
	}
	mkdir $powerShellPath | Out-Null
	mkdir $packageToolsPath | Out-Null
	copy "$rootPath\..\bin\Debug\NugetShared\*" $powerShellPath
	$config | Set-Content -Path $toolConfigPath -Encoding UTF8
	Import-Module "$powerShellPath\NugetShared.psm1" -Global -DisableNameChecking

	$config | Set-Content -Path $toolConfigPath
}