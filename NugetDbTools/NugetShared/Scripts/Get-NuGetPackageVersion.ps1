function Get-NuGetPackageVersion {
	<#.Synopsis
	Get the latest version number of the package
	.DESCRIPTION
	Retrieves the latest version number of the specified package in the local NuGet server
	.EXAMPLE
	$ver = Get-NuGetPackageVersion -PackageName 'BackOfficeAudit.Logging'
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The NuGet package name
		[string]$PackageName,
		# The optional Branch - Prerelease label
		[string]$Branch = $null
	)
	$cmd = "nuget list $PackageName -Source '$(Get-NuGetLocalSource)'"
	if ($Branch) {
		$cmd += ' -Prerelease -AllVersions'
	}
	$nameVersions = Invoke-Expression $cmd | Where-Object { $_.StartsWith("$PackageName ") } | ForEach-Object {
		[string[]]$nameVersion = $_.Split(' ')
		[string[]]$versionBranch = $nameVersion[1].Split('-', 2)
		New-Object -TypeName PSCustomObject -Property @{
			name = $nameVersion[0]
			versionBranch = $nameVersion[1]
			version = $versionBranch[0]
			branch = $versionBranch[1]
		}
	}
	if ($Branch) {
		$selection = $nameVersions | Where-Object { $_.branch -eq $Branch } | Select-Object -First 1
		if (-not $selection) {
			$selection = $nameVersions | Where-Object { -not $_.branch } | Select-Object -First 1
		}
	} else {
		$selection = $nameVersions | Where-Object { -not $_.branch } | Select-Object -First 1
	}
	if ($selection) {
		return $selection.versionBranch
	} else {
		return ''
	}
}