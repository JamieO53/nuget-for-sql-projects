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
        # The NuGet package specification path
		[string]$NuspecPath,
		# The location of the NuGet data
        [string]$NugetFolder,
		# The folder where the package is created
		[string]$PackageFolder 
	)
	NuGet pack $NuspecPath -BasePath $NugetFolder -OutputDirectory $PackageFolder
}
