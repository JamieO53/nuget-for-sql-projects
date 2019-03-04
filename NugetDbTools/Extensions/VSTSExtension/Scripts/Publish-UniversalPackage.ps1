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
		az login --username Builder@ecentric.co.za --password $env:BuilderPassword
		az devops configure --defaults organzation=https://dev.azure.com/epsdev project=$PackageName
		az artifacts universal publish --organization https://dev.azure.com/epsdev --feed TestFeed --name $PackageName --version $PackageVersion --description $PackageDescription -Path "$PackageFolder\$PackageName"
	} finally {
		az logout --username 'Builder@ecentric.co.za'
	}
}