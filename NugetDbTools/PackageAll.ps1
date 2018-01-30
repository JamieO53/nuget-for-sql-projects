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
		powershell.exe -OutputFormat Text -command '.\Package.ps1'
		popd
		if ($LASTEXITCODE) {
			Write-Error "Package of NugetSharedPacker failed" -ErrorAction Stop
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
		Write-Host $_.Exception.Message -ForegroundColor Red
		exit 1
	} finally {
		popd
	}
}