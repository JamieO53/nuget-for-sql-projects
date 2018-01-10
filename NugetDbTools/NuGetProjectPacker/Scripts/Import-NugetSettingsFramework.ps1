function Import-NugetSettingsFramework {
	<#.Synopsis
	Import NuGet settings from a .Net Framework project
	.DESCRIPTION
	Import the NuGet spec settings from the project the project's packages configuration file (packages.config)
	.EXAMPLE
	Import-NugetSettingsFramework -ProjectPath '.\Triton.Triton.csproj'
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The location of .csproj file of the project being packaged
        [string]$ProjectPath
	)
	$nugetSettings = New-NuGetSettings
	$projectFolder = Split-Path -Path $ProjectPath
	$projectName = (Split-Path -Path $ProjectPath -Leaf).Split('.')[0];
	$specPath = Join-Path -Path $projectFolder -ChildPath Package.nuspec
	$pkgPath = Join-Path -Path $projectFolder -ChildPath packages.config
	if (Test-Path $specPath) {
		[xml]$spec = gc $specPath
		$spec.package.metadata |
			Get-Member |
			where { ($_.MemberType -eq 'Property') -and ($_.Name -ne 'dependencies') } | % {
				$name = $_.Name
				if ($name -eq 'version') {
					[string]$version = Get-NuspecProperty -Spec $spec -Property version
					$verParts = $version.Split('.')
					$nugetSettings.nugetOptions.MajorVersion = $verParts[0]
					$nugetSettings.nugetOptions.MinorVersion = $verParts[1]
				} else {
					$nugetSettings.nugetSettings[$name] = Get-NuspecProperty -Spec $spec -Property $name
				}
			}
	}
	if (Test-Path $pkgPath) {
		[xml]$pkg = gc $pkgPath
		$pkg.packages.package | % {
			$nugetSettings.nugetDependencies[$_.id] = $_.version
		}
	}
	$nugetSettings
}