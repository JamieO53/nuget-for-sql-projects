function Publish-UniversalPackage {
    [CmdletBinding()]
    param
    (
        # The package contents folder
		[string]$PackageFolder,
		# The name of the package
		[string]$PackageName,
		# The version of the new package
		[string]$PackageVersion,
		# The description of the package
		[string]$PackageDescription
	)
	try {
		$login = Invoke-Trap -Command "az login --username Builder@ecentric.co.za --password $env:BuilderPassword --allow-no-subscriptions" -Message 'Publish-UniversalPackage: Login failed' -Fatal | ConvertFrom-Json
		Invoke-Trap -Command "az devops configure --defaults organization=https://dev.azure.com/epsdev project=$PackageName" -Message 'Publish-UniversalPackage: Defaults configuration failed' -Fatal
		Invoke-Trap -Command "az artifacts universal publish --feed TestFeed --name $PackageName --version $PackageVersion --description $PackageDescription -Path $PackageFolder\$PackageName" -Message 'Publish-UniversalPackage: Artifact publication failed' -Fatal
	} finally {
		Invoke-Trap -Command "az logout --username Builder@ecentric.co.za" -Message 'Publish-UniversalPackage: Logout failed' -Fatal
	}
}