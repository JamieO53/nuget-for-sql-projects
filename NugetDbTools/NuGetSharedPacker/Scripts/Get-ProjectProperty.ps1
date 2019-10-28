function Get-ProjectProperty {
	<#.Synopsis
	Get the named property from the project
	.DESCRIPTION
	Get the named property from the project's XML document
	.EXAMPLE
	Get-ProjectProperty -Proj $proj -Property AssemblyName
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Proj,
		# The property being queried
		[string]$Property
	)
	[string]$prop = Invoke-Expression "`$proj.Project.PropertyGroup.$Property"
	$prop = $prop.Trim()
	return $prop
}