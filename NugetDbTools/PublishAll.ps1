if (git status --porcelain) {
	Write-Error 'Commit changes before publishing the projects to NuGet'
}
else {
	& '.\NugetShared\Publish.ps1'
	& '.\NugetSharedPacker\Publish.ps1'
	& '.\NugetDbPacker\Publish.ps1'
	& '.\NugetProjectPacker\Publish.ps1'
	& '.\DbSolutionBuilder\Publish.ps1'
}