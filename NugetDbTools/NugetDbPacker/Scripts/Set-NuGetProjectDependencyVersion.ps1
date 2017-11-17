function Set-NuGetProjectDependencyVersion {
	<#.Synopsis
	Update the SQL project's NuGet dependendency version
	.DESCRIPTION
    Checks if SQL project if it has a NuGet dependency on the given dependency. If it does, the version is updated to the given value.
	.EXAMPLE
	Set-NuGetProjectDependencyVersion -NugetConfigPath C:\VSTS\Batch\Batching\.nuget.config -Dependency 'BackOfficeStateManager.StateManager' -Version '0.1.2'
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .nuget.config file being updated
        [string]$NugetConfigPath,
		# The dependency being updated
		[string]$Dependency,
		# The new package version
		[string]$Version
	)

	$cfg = Import-NuGetSettings -NugetConfigPath $NugetConfigPath
		if ($cfg.nugetDependencies[$Dependency]) {
			$cfg.nugetDependencies[$Dependency] = $Version
		}
 	Export-NuGetSettings -NugetConfigPath $NugetConfigPath -Settings $cfg
}