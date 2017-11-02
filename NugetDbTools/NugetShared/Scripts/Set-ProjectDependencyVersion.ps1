function Set-ProjectDependencyVersion {
<#.Synopsis
	Set the dependency's version in the project file to the latest version on the server.
.DESCRIPTION
	Fetches the dependency's latest version number and sets it in the project file.
.EXAMPLE
	Set-ProjectDependencyVersion -Path .\BackOfficeAuditPkg\BackOfficeAuditPkg.csproj -Dependency NuGetDbPacker
#>
    [CmdletBinding()]
    param
    (
        # The path of the project file
		[string]$Path,
		# The dependency name
		[string]$Dependency
	)
	$newVersion = Get-NuGetPackageVersion $Dependency
	[xml]$proj = gc $Path
	$refs = $proj.Project.ItemGroup | ? { $_.PackageReference }
	$ref = $refs.PackageReference | ? { $_.Include -eq $Dependency }
	if ($ref) {
		$ref.Version = $newVersion
	} else {
		[xml]$new = "<new><PackageReference Include=`"$Dependency`" Version=`"$newVersion`" /></new>"
		$node = $refs.AppendChild($refs.OwnerDocument.ImportNode($new.new.FirstChild, $true))
	}
	Out-FormattedXml -Xml $proj -FilePath $Path
}
