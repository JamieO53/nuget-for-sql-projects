function Import-NugetSettingsFramework {
	<#.Synopsis
	Import NuGet settings from a .Net Framework project
	.DESCRIPTION
	Import the NuGet spec settings from the project the project's packages configuration file (packages.config)
	.EXAMPLE
	Import-NugetSettingsFramework -NuspecPath '.\Package.nuspec'
	.EXAMPLE
	Import-NugetSettingsFramework -NuspecPath '.\Package.nuspec' -PackagesConfigPath '.\AtlasCore\packages.config'
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The location of the .nuspec file of the package
        [string]$NuspecPath,
		# The location of the Packages.config file of the solution
		[string]$PackagesConfigPath = $null
	)
	$nugetSettings = New-NuGetSettings
	if (Test-Path $NuspecPath) {
		[xml]$spec = Get-Content $NuspecPath
		$spec.package.metadata |
			Get-Member |
			Where-Object { ($_.MemberType -eq 'Property') -and ($_.Name -ne 'dependencies') } | ForEach-Object {
				$name = $_.Name
				if ($name -eq 'version') {
					[string]$version = Get-NuspecProperty -Spec $spec -Property version
					$verParts = $version.Split('.')
					$nugetSettings.nugetOptions.MajorVersion = $verParts[0]
					$nugetSettings.nugetOptions.MinorVersion = $verParts[1]
				}
				$nugetSettings.nugetSettings[$name] = Get-NuspecProperty -Spec $spec -Property $name
			}
		if ($spec.package.metadata.dependencies) {
			$spec.package.metadata.dependencies.dependency | ForEach-Object {
				$nugetSettings.nugetDependencies[$_.id] = $_.version
			}
		}
	}
	if (Test-Path $PackagesConfigPath) {
		[xml]$pkg = Get-Content $PackagesConfigPath
		$pkg.packages.package | ForEach-Object {
			if ($nugetSettings.nugetDependencies.ContainsKey($_.id)) {
				$nugetSettings.nugetDependencies[$_.id] = $_.version
			}
		}
	}
	$nugetSettings
}