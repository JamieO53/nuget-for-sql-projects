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
	$proj.Project.PropertyGroup | % {
		if ($_.Condition) {
			[string]$cond = $_.Condition
			$cond = $cond.Replace('$(Configuration)', $Configuration)
			$cond = $cond.Replace('$(Platform)', $Platform)
			$cond = $cond.Replace('==', '-eq')
			[bool]$isCond = (iex $cond)
		} else {
			[bool]$isCond = $true
		}
		if ($isCond) {
			[string]$prop = iex "`$_.$Property"
			$prop = $prop.Trim()
			return $prop
		}
	}
	return ''
}

