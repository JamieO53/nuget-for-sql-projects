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
	$packageFolder = "$SolutionFolder\Packages"
	$contentFolder = Get-NuGetContentFolder
	$solutionContentFolder = "$SolutionFolder\$contentFolder"

	if (Test-Path $packageContentFolder) {
		if (-not $global:testing)
		{
			del $packageContentFolder\* -Recurse -Force
		}
	} else {
		mkdir $packageContentFolder | Out-Null
	}
	
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	rmdir "$SolutionPath\Databases*" -Recurse -Force
	ls $packageContentFolder -Directory | % {
		ls $_.FullName -Directory | ? { (ls $_.FullName -Exclude _._).Count -ne 0 } | % {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)" -Recurse -Force
		}
	}

	del $packageContentFolder -Include '*' -Recurse -Force

	if ((Test-Path $packageFolder) -and (ls "$packageFolder\**\$contentFolder" -Recurse)) {
		if (Test-Path $solutionContentFolder) {
			rmdir $solutionContentFolder* -Recurse -Force
		}
		mkdir $solutionContentFolder | Out-Null
		ls "$packageFolder\**\$contentFolder" -Recurse | % {
			copy "$($_.FullName)\*" $solutionContentFolder -Recurse -Force
		}
	}
}