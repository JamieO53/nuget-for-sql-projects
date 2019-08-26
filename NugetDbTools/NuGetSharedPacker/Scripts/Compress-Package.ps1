function Compress-Package {
	<#.Synopsis
	Pack the NuGet package
	.DESCRIPTION
	Uses the NuGet command to create the nuget package from the data at the specified location
	.EXAMPLE
	Compress-Package -NugetPath .\Nuget
	#>
    [CmdletBinding()]
    param
    (
        # The location of the NuGet data
        [string]$NugetPath
	)
	Push-Location -LiteralPath $NugetPath
	NuGet pack -BasePath $NugetPath
	Pop-Location
}
