function Compress-DbPackage
{
	<#.Synopsis
	Pack the database NuGet package
	.DESCRIPTION
	Uses the NuGet command to create the nuget package from the data at the specified location
	.EXAMPLE
	Compress-DbPackage -NugetPath .\Nuget
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
