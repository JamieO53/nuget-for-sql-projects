function Test-PathIsCommitted {
	<#.Synopsis
	Test if the Path has been committed
	.DESCRIPTION
	Checks if the path is in a git repo and has been committed
	.EXAMPLE
	if (Test-PathIsCommitted -Path C:\VSTS\EcsShared\SupportRoles)
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The path being tested
		[string]$Path
	)
	try {
		pushd $Path
		(Test-PathIsInGitRepo -Path .) -and ([string]::IsNullOrEmpty((iex 'git status --porcelain')))
	} finally {
		popd
	}
}