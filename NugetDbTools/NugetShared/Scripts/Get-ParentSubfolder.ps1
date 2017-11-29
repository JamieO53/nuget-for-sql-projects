function Get-ParentSubfolder
{
	<#.Synopsis
	Search the folders in the Path for a match to the filter
	.DESCRIPTION
	Search the Path and its parents until the Filter is matched
	The path containing the successful match is returned otherwise a empty string
	.EXAMPLE
	Get-ParentSubfolder -Path . -Filter '*.sln'
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The path being tested
		[string]$Path,
        # The pattern being matched
        [string]$Filter
	)
	[string]$myPath = (Resolve-Path $Path).Path
	while ($myPath -and -not (Test-Path ([IO.Path]::Combine($myPath,$Filter)))) {
		$myPath = Split-Path $myPath
	}
	if ([string]::IsNullOrEmpty($myPath)) {
		return ''
	} else {
		 return $myPath
		}
}