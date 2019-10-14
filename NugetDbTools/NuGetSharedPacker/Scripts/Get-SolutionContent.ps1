function Get-SolutionContent {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionContent -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"
	$packageFolder = "$SolutionFolder\packages"
	$contentFolder = Get-NuGetContentFolder
	$solutionContentFolder = "$SolutionFolder\$contentFolder"

	if (-not $contentFolder) {
		$configFolder = (Get-Item (Get-NuGetDbToolsConfigPath)).FullName
		Log "Content folder not specified in $configFolder" -Error
		exit 1
	}

	Log "Get solution packages: $SolutionPath"
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	Remove-Item "$SolutionPath\Databases*" -Recurse -Force
	Get-ChildItem $packageContentFolder -Directory | ForEach-Object {
		Get-ChildItem $_.FullName -Directory | Where-Object { (Get-ChildItem $_.FullName -Exclude _._).Count -ne 0 } | ForEach-Object {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			Copy-Item "$($_.FullName)\*" "$SolutionFolder\$($_.Name)\" -Recurse -Force
		}
	}

	Remove-Item $packageContentFolder* -Recurse -Force

	$csPackage = @{}
	Get-ChildItem .\**\packages.config | ForEach-Object {
		[xml]$pc = Get-Content $_
		$pc.packages.package | ForEach-Object {
			New-Object -TypeName PSCustomObject -Property @{ id=$_.id; version=$_.version }
		}
	} | Sort-Object -Property id,version -Unique | ForEach-Object {
		$csPackage[$_.id] = $_.version
	}
	
	if ((Test-Path $packageFolder) -and (Get-ChildItem "$packageFolder\**\$contentFolder" -Recurse)) {
		if (Test-Path $solutionContentFolder) {
			Remove-Item $solutionContentFolder\* -Recurse -Force
		} else {
			mkdir $solutionContentFolder | Out-Null
		}
		$csPackage.Keys | Sort-Object | ForEach-Object {
			$id = $_
			$version = $csPackage[$id]
			$idContentFolder = "$packageFolder\$id.$version\content\$contentFolder"
			if (Test-Path $idContentFolder) {
				Copy-Item "$idContentFolder\*" "$solutionContentFolder\" -Recurse -Force
			}
		}
	}
}