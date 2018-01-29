if (git status --porcelain) {
	Write-Error 'Commit changes before publishing the projects to NuGet'
}
else {
	Remove-Variable * -ErrorAction Ignore
	pushd '.\NugetShared'
	& '.\Package.ps1'
	popd
	pushd '.\NugetSharedPacker'
	& '.\Package.ps1'
	popd
	pushd '.\NugetDbPacker'
	& '.\Package.ps1'
	popd
	pushd '.\NugetProjectPacker'
	& '.\Package.ps1'
	popd
	pushd '.\DbSolutionBuilder'
	& '.\Package.ps1'
	popd
}