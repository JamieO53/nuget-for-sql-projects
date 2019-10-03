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

	Get-PkgProjects $SolutionPath | ForEach-Object {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$assetPath = "$projFolder\obj\project.assets.json"

		nuget restore $projPath -Source (Get-NuGetLocalSource) | Out-Null

		$assets = ConvertFrom-Json (Get-Content $assetPath | Out-String)
		$dep = Get-AssetDependencies($assets)
		$lib = Get-AssetLibraries($assets)
		$tgt = Get-AssetTargets($assets)

		$deps = $dep
		while ($deps.Count -gt 0) {
			$refs = $deps
			$deps = @{}
			$refs.Keys | ForEach-Object {
				if (-not $reference[$_]) {
					$reference[$_] = $lib[$_]
					if ($tgt[$_]) {
						$tgt[$_] | Where-Object { -not $reference[$_] } | ForEach-Object {
							$deps[$_] = $lib[$_]
						}
					}
				}
			}
		}
	}
	$reference
}