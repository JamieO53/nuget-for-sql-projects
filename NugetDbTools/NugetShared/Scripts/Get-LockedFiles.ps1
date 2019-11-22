function Get-LockedFiles {
	<#.Synopsis
	Identifies locked files in the folder
	.DESCRIPTION
    Gets a list of files that can be opened with normal credentials
	.EXAMPLE
	[string[]]$locked = Get-LockedFiles -Path C:\VSTS\Batch
	Get-ChildItem -Path C:\VSTS\Batch -Recurse -Exclude $locked
	#>
	[CmdletBinding()]
	[OutputType([string[]])]
    param
    (
        # The folder being tested
        [string]$Folder
	)
	[string[]]$locked = @()
	Get-ChildItem $Folder -Recurse -Force | Where-Object { -not (Test-IsDirectory $_) } | ForEach-Object {
		if ((Test-PathIsLocked $_.FullName) -or (Get-Owner -Path $_.FullName) -eq 'BUILTIN\Administrators') {
			$locked += $_.Name
		}
	}
	return $locked
}
