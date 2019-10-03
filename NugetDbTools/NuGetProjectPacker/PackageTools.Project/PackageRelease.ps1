$projectType = 'Release'

try {
	if (Test-Path "$PSScriptRoot\*.sln") {
		$slnFolder = (Get-Item "$PSScriptRoot").FullName
	} elseif (Test-Path "$PSScriptRoot\..\*.sln") {
		$slnFolder = (Get-Item "$PSScriptRoot\..").FullName
	} else {
		throw 'Package Release: Unable to find the solution file'
	}
	$slnPath = (Get-Item "$slnFolder\*.sln") | Select-Item -First 1 | ForEach-Object { $_.FullName }
	
	if (-not (Get-Module NuGetProjectPacker)) {
		Import-Module "$slnFolder\PowerShell\NuGetProjectPacker.psd1" -Global -DisableNameChecking
	}

	$releaseConfigPath = "$slnFolder\PackageRelease.config"
	if (-not (Test-Path $releaseConfigPath)) {
		throw 'Unable to find the PackageRelease.config file in solution folder'
	}
	[xml]$config = Get-Content $releaseConfigPath
	$releaseFolder = "$slnFolder\$($config.package.metadata.releaseFolder)"
	$contentFolders = $config.package.metadata.content.contentFolder | ForEach-Object { $_ }
	$contentFiles = $config.package.metadata.content.contentFile | ForEach-Object { $_ }
	$releaseBinFolder = "$slnFolder\$($config.package.metadata.binaryReleaseFolder)"
	$releaseContentFolder = "$releaseFolder\$content"
	$releaseDbFolder = "$slnFolder\$($config.package.metadata.databaseReleaseFolder)"
	[bool]$clearReleaseFolder = $config.package.metadata.clear -eq 'True'
	[bool]$includeBinary = $config.package.metadata.includeBinary -eq 'True'
	[bool]$includeContent = $config.package.metadata.includeContent -eq 'True'

	Push-Location $slnFolder

	$csProject = @{}
	Get-CSharpProjects -SolutionPath $slnPath | ForEach-Object {
		$csProject[$_.Project] = "$slnFolder\$($_.ProjectPath)"
	}

	$dbProject = @{}
	Get-SqlProjects -SolutionPath $slnPath | ForEach-Object {
		$dbProject[$_.Project] = "$slnFolder\$($_.ProjectPath)"
	}

	if ($clearReleaseFolder -and (Test-Path $releaseFolder)) {
		Remove-NugetFolder $releaseFolder
	}

	if ($includeBinary -and -not (Test-Path $releaseBinFolder)) {
		mkdir $releaseBinFolder | Out-Null		
	}
	if ($includeContent -and -not (Test-Path $releaseContentFolder)) {
		mkdir $releaseContentFolder | Out-Null		
	}
	if (($dbProject.Count -gt 0) -and -not (Test-Path $releaseDbFolder)) {
		mkdir $releaseDbFolder | Out-Null		
	}

	if ($includeBinary) {
		$config.package.metadata.projects.netProject | ForEach-Object {
			$projName = $_
			if ($csProject.ContainsKey($projName)) {
				$projPath = $csProject[$projName]
				$projFolder = Split-Path $projPath
				$projBinFolder = "$projFolder\bin\$buildConfig"

				Import-ArtifactProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -ArtifactBinFolder $releaseBinFolder -DefaultAssemblyName $projName
				Move-Item $releaseBinFolder\content\* $releaseBinFolder\ -Force
				Remove-Item $releaseBinFolder\content
			} else {
				throw "Project $projName is not in the solution"
			}
		}
	}

	if ($includeContent) {
		Copy-Item $contentFolder\* $releaseContentFolder\ -Recurse -Force
		$config.package.metadata.projects.netProject | ForEach-Object {
			$projName = $_
			if ($csProject.ContainsKey($projName)) {
				$projPath = $csProject[$projName]
				$projFolder = Split-Path $projPath
				$projContentFolder = "$projFolder\$content"
				if (Test-Path $projContentFolder) {
					Copy-Item $projContentFolder\* $releaseContentFolder\ -Recurse -Force
				}
			}
		}
	}

	if (Test-Path "$slnFolder\Databases") {
		Copy-Item "$slnFolder\**\Databases\*" $releaseDbFolder\ -Recurse -Force
		Copy-Item "$slnFolder\Databases\*" $releaseDbFolder\ -Recurse -Force
	}

	$contentFolders | ForEach-Object {
		if (Test-Path "$slnFolder\$_") {
			if (-not (Test-Path "$releaseFolder\$_")) {
				mkdir "$releaseFolder\$_"
			}
			Copy-Item "$slnFolder\$_\*" "$releaseFolder\$_\" -Recurse -Force
		}
	}
	$contentFiles | ForEach-Object {
		if (Test-Path "$slnFolder\$_") {
			Copy-Item "$slnFolder\$_" $releaseFolder -Force
		}
	}

	$config.package.metadata.projects.dbProject | ForEach-Object {
		$projName = $_
		if ($dbProject.ContainsKey($projName)) {
			$projPath = $dbProject[$projName]
			$projFolder = Split-Path $projPath
			Copy-Item "$projFolder\Databases\*" $releaseDbFolder\ -Recurse
			Copy-Item "$projFolder\*.publish.xml" $releaseDbFolder\
		} else {
			throw "Database project $projName is not in the solution"
		}
	}

} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host $_.Exception.StackTrace
	Exit 1
} finally {
	Pop-Location
}
