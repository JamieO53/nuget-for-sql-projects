function Step-Version {
<#.Synopsis
	Increases the release count of the version
.DESCRIPTION
	Increases the third part of the version.
.EXAMPLE
	$ver = Step-Version -Version 1.0.123
	# $ver -eq 1.0.124
.EXAMPLE
	$ver = Step-Version -Version 1.0.123-Branch
	# $ver -eq 1.0.124-Branch
#>
    [CmdletBinding()]
    param
    (
		#Version being increased
		[string]$Version
	)

	$parts = $Version.Split('.',3)
	$major = $parts[0]
	$minor = $parts[1]
	$revisions = $parts[2]

	$revParts = $revisions.Split('-',2)

	[int]$newRev = $revParts[0]
	$newRev += 1
	$branch = ''
	if ($revParts.Count -eq 2) {
		$branch = "-$($revParts[1])"
	}
	return "$major.$minor.$newRev$($branch)"
}