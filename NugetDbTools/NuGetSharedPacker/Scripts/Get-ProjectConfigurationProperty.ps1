function Get-ProjectConfigurationProperty {
	<#.Synopsis
	Get the named property from the project for a specific configuration
	.DESCRIPTION
	Get the named property from the project's XML document for the specified build configuration and platform
	.EXAMPLE
	Get-ProjectProperty -Proj $proj -Property AssemblyName
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Proj,
		# The property being queried
		[string]$Property,
		# The build configuration
		[string]$Configuration,
		# The build platform
		[string]$Platform
	)
	[string]$prop = ''
	$proj.Project.PropertyGroup | ForEach-Object {
		if ($_.Condition) {
			[string]$cond = $_.Condition
			$cond = $cond.Replace('$(Configuration)', $Configuration)
			$cond = $cond.Replace('$(Platform)', $Platform)
			$cond = $cond.Replace('==', '-eq')
			[bool]$isCond = (Invoke-Expression $cond)
		} else {
			[bool]$isCond = -not [string]::IsNullOrWhiteSpace((Invoke-Expression "`$_.$Property"))
		}
		if ($isCond) {
			$prop = Invoke-Expression "`$_.$Property"
			$prop = $prop.Trim()
		}
	}
	return $prop
}

