function Test-IsDirectory {
	<#.Synopsis
	Checks if the item is a directory
	.DESCRIPTION
    Tests if the file can be opened exclusively
	.EXAMPLE
	if (Test-IsDirectory -Info (Get-Item C:\VSTS\Batch)) {
		Get-ChildItem C:\VSTS\Batch -Recurse
	}
	#>
	[CmdletBinding()]
	[OutputType([bool])]
    param
    (
        # The folder being tested
        [System.IO.FileSystemInfo]$Info
	)
	return $Info.GetType().Name -eq 'DirectoryInfo'
}
