function Set-Label {
	<#.Synopsis
	Sets the Label or Tag for the current repository
	.DESCRIPTION
    Sets the Label or Tag for the current repository.
    The label is assumed to be formated thus: "v$version" or "v$version-$branch" where $version is
    "$major.$minor.$patch", $patch is the project's commit count, and $branch is the repository branch.
    No branch is specified for the master branch.
	.EXAMPLE
	Set-Label -Label v1.0.123
	#>
    [CmdletBinding()]
    param (
        # The label text
		[string]$Label
	)
    git tag -a $label -m "Publish $Label"
}