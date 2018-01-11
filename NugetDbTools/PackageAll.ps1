if (git status --porcelain) {
	Write-Error 'Commit changes before publishing the projects to NuGet'
}
else {
	Remove-Variable * -ErrorAction SilentlyContinue
	& '.\NugetShared\Package.ps1'
	& '.\NugetSharedPacker\Package.ps1'
	& '.\NugetDbPacker\Package.ps1'
	& '.\NugetProjectPacker\Package.ps1'
	& '.\DbSolutionBuilder\Package.ps1'
}