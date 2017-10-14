function Test-CiDataAvailable {
	<#.Synopsis
	Tests if the CI data is available
	.DESCRIPTION
	Checks if the project's Dependency data is available
	.EXAMPLE
	if (-not (Test-CiDataAvailable -SolutionName 'RetailReconFees')) {...}
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The CI project name
		[string]$SolutionName
	)
	$result = $true
	if (-not (Test-Path "$env:DevBase\$SolutionName\trunk\RunTime.annexures\Dependencies.xml")) {
		Write-Host "Unable to find CI information for $SolutionName" -ForegroundColor DarkRed
		$result = $false
	} elseif (-not (Test-Path "$env:DevBase\$SolutionName\trunk\runtime\$SolutionName-Dependencies.xml")) {
		Write-Host 'Insufficient information available to determine inherited dependencies' -ForegroundColor DarkRed
		Write-Host 'Do a GetDependencies, Build and Deploy before proceeding' -ForegroundColor DarkRed
		$result = $false
	} elseif (-not (Test-Path "$env:DevBase\$SolutionName\trunk\runtime\$SolutionName-Deploy.xml")) {
		Write-Host 'Insufficient information available to determine the SQLCMD variables' -ForegroundColor DarkRed
		Write-Host 'Do a GetDependencies, Build and Deploy before proceeding' -ForegroundColor DarkRed
		$result = $false
	}
	return $result
}