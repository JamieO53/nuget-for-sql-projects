
function Get-PackageTools {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-PackageTools -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"

    Log "Get tool packages: $SolutionPath"
	Get-PackageToolsPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	Get-ChildItem $packageContentFolder -Directory | ForEach-Object {
		Get-ChildItem $_.FullName -Directory | Where-Object { (Get-ChildItem $_.FullName -Exclude _._).Count -ne 0 } | ForEach-Object {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			Copy-Item "$($_.FullName)\*" "$solutionFolder\$($_.Name)\" -Recurse -Force
		}
	}

	Remove-Item $packageContentFolder -Include '*' -Recurse -Force
}