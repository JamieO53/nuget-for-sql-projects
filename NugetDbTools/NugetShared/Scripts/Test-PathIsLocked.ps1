function Test-PathIsLocked {
	<#.Synopsis
	Is the file locked?
	.DESCRIPTION
		Tests if the file can be opened exclusively
	.EXAMPLE
	if (Test-PathIsLocked -Path C:\VSTS\Batch\Batch.sln) {...}
	#>
	[CmdletBinding()]
	[OutputType([bool])]
	param
	(
		# The path of the file being tested
		[string]$Path
	)
	
	$args = @($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
	$isLocked = $false
	try {
		$fs = New-Object -TypeName System.IO.FileStream -ArgumentList $args
	} catch {
		$isLocked = $true
	} finally {
		if ($fs) {
			if ($fs.CanRead) {
				$fs.Close()
			}
			$fs.Dispose()
		}
	}
	return $isLocked
}
