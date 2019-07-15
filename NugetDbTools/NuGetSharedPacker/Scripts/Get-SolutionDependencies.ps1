function Get-SolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
	$slnFolder = Split-Path -Path $SolutionPath
	nuget restore $SolutionPath | Out-Null

	Get-PkgProjects $SolutionPath | % {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$assetPath = "$projFolder\obj\project.assets.json"

		nuget restore $projPath -Source (Get-NuGetLocalSource) | Out-Null

		$assets = ConvertFrom-Json (gc $assetPath | Out-String)
		$assets.libraries | Get-Member |
			where { $_.MemberType -eq 'NoteProperty' } |
			select -Property Name | 
			where { Test-Path "$env:UserProfile\.nuget\packages\$($_.Name)" } | 
			foreach {
				[string]$ref = $_.Name
				$pkgver = $ref.Split('/')
				$package = $pkgver[0]
				$version = $pkgver[1]
				$reference[$package] = $version
			}
	}
	$reference
}