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
		$login = az login --username Builder@ecentric.co.za --password $env:BuilderPassword --allow-no-subscriptions | ConvertFrom-Json
		az devops configure --defaults organization=https://dev.azure.com/epsdev project=$PackageName
		az artifacts universal publish --feed TestFeed --name $PackageName --version $PackageVersion --description $PackageDescription -Path "$PackageFolder\$PackageName"
	} finally {
		az logout --username 'Builder@ecentric.co.za'
	}
}