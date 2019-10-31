function Get-Label {
	<#.Synopsis
	Gets the highest Label or Tag for the current repository
	.DESCRIPTION
    Sorts the lables or tags in the current repository semantically, and returns the highest one.
    The label is assumed to be formated thus: "$prefix$version" or "$prefix$version-$branch" where $version is
    "$major.$minor.$patch", $patch is the project's commit count, and $branch is the repository branch.
    No branch is specified for the master branch.
    The $major, $minor and $patch values are sorted numerically, while the $branch values is sorted alphabetically.
    The label or tag with no branch is higher than those with
	.EXAMPLE
	Set-Label -Label v1.0.123
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [string]$Prefix
    )
    if ($Prefix) {
        $labels = git tag --list "$Prefix*" | Where-Object { $_ -match "^$Prefix[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\-.*)?" }
    } else {
        $labels = git tag --list | Where-Object { $_ -match '^[0-9]+\.[0-9]+(\.[0-9]+)?(\.[0-9]+)?(\-.*)?' }
    } 
    $result = ''
    $result = $labels | ForEach-Object {
        $label = $_
        if ($Prefix) {
            $tail = $label.Replace($Prefix, '')
        } else {
            $tail = $label
        }
        $versionBranch = $tail.Split('-', 2)
        [string]$version = $versionBranch[0]
        if ($versionBranch.Count -eq 2) {
            [string]$branch = $versionBranch[1]
        } else {
            [string]$branch = [char]::MaxValue
        }
        $versionParts = $version.Split('.')
        [int]$major = $versionParts[0]
        [int]$minor = $versionParts[1]
        if ($versionParts.Count -gt 2) {
            [int]$patch = $versionParts[2]
            if ($versionParts.Count -gt 3) {
                [int]$build = $versionParts[3]
            } else {
                [int]$build = 0
            }
        } else {
            [int]$patch = 0
            [int]$build = 0
        }
        New-Object -TypeName PSCustomObject -Property @{
            major = $major
            minor = $minor
            patch = $patch
            build = $build
            branch = $branch
            label = $label
        }
    } | Sort-Object -Property major,minor,patch,build,branch -Descending | Select-Object -First 1 | ForEach-Object {
        $_.label
    }
    return $result
}