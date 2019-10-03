function Get-NuspecProperty {
	<#.Synopsis
	Get the named property from the project
	.DESCRIPTION
	Get the named property from the nuspec's XML document
	.EXAMPLE
	Get-NuspecProperty -Spec $spec -Property version
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Spec,
		# The property being queried
		[string]$Property
	)
	[string]$prop = Invoke-Expression "`$spec.package.metadata.$Property"
	return $prop.Trim()
}