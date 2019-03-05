function Test-PathIsInGitRepo {
	<#.Synopsis
	Test if the Path is in a Git repository
	.DESCRIPTION
	Search the Path and its parents until the .git folder is found
	.EXAMPLE
	if (Test-PathIsInGitRepo -Path C:\VSTS\EcsShared\SupportRoles)
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The path being tested
		[string]$Path
	)
	[string]$myPath = Get-ParentSubfolder -Path $Path -Filter '.git'
	return $myPath -ne ''
}
