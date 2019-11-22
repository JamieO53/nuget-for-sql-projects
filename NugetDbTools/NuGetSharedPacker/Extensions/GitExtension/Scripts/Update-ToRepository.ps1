function Update-ToRepository {
	<#.Synopsis
	Commits the changes
	.DESCRIPTION
    Commits changese to the given file to the current repository.
	.EXAMPLE
	Update-ToRepository -Path $projectFolder\Package.nuspec -Message 'BATCH update dependency versions'
	#>
    [CmdletBinding()]
    param (
        # The path of the file being committed
		[string]$Path,
		# The commit message
		[string]$Message
	)
	Invoke-Expression "git commit -m `"$Message`" -- $Path"
}