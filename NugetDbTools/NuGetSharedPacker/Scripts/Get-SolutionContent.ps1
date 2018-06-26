function Get-SolutionContent {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"

	if (Test-Path $packageContentFolder) {
		if (-not $global:testing)
		{
			del $packageContentFolder\* -Recurse -Force
		}
	} else {
		mkdir $packageContentFolder | Out-Null
	}
	
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	ls $packageContentFolder -Directory | % {
		ls $_.FullName -Directory | % {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)"
			}
			copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
		}
	}

	del $packageContentFolder\ -Include '*' -Recurse
}