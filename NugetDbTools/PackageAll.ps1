if (git status --porcelain) {
	Write-Error 'Commit changes before publishing the projects to NuGet'
}
else {
	Remove-Variable * -ErrorAction SilentlyContinue
	try {
		pushd '.\NugetShared'
		powershell.exe -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			throw "Package of NugetShared failed"
		}
		pushd '.\NugetSharedPacker'
		powershell.exe -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			throw "Package of NugetSharedPacker failed"
		}
		pushd '.\NugetDbPacker'
		powershell.exe -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			throw "Package of NugetDbPacker failed"
		}
		pushd '.\NugetProjectPacker'
		powershell.exe -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			throw "Package of NugetProjectPacker failed"
		}
		pushd '.\DbSolutionBuilder'
		powershell.exe -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			throw "Package of DbSolutionBuilder failed"
		}
	} catch {
		Write-Host $_.Message
	}
}