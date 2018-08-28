if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module .\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1
}
# if (-not (Test-IsRunningBuildAgent) -and -not (Test-PathIsCommitted)) {
	# Write-Error 'Commit changes before publishing the projects to NuGet'
# }
Remove-Variable * -ErrorAction SilentlyContinue
$buildSequence = @('NugetShared','NuGetSharedPacker','NugetDbPacker','NuGetProjectPacker','DbSolutionBuilder')
try {
	$buildSequence | % {
		pushd ".\$_"
		powershell.exe -command '.\Package.ps1'
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