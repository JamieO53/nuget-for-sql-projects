$projectType = 'Release'

try {
	if (Test-Path "$PSScriptRoot\*.sln") {
		$slnFolder = (Get-Item "$PSScriptRoot").FullName
	} elseif (Test-Path "$PSScriptRoot\..\*.sln") {
		$slnFolder = (Get-Item "$PSScriptRoot\..").FullName
	} else {
		throw 'Package Release: Unable to find the solution file'
	}
	$slnPath = (Get-Item "$slnFolder\*.sln") | select -First 1 | % { $_.FullName }
	
	if (-not (Get-Module NuGetProjectPacker)) {
		Import-Module "$slnFolder\PowerShell\NuGetProjectPacker.psd1" -Global -DisableNameChecking
	}

	$releaseConfigPath = "$slnFolder\PackageRelease.config"
	if (-not (Test-Path $releaseConfigPath)) {
		throw 'Unable to find the PackageRelease.config file in solution folder'
	}
	[xml]$config = gc $releaseConfigPath
	$releaseFolder = "$slnFolder\$($config.package.metadata.releaseFolder)"
	$contentFolders = $config.package.metadata.content.contentFolder | % { $_ }
	$contentFiles = $config.package.metadata.content.contentFile | % { $_ }
	$releaseBinFolder = "$slnFolder\$($config.package.metadata.binaryReleaseFolder)"
	$releaseContentFolder = "$releaseFolder\$content"
	$releaseDbFolder = "$slnFolder\$($config.package.metadata.databaseReleaseFolder)"
	[bool]$clearReleaseFolder = $config.package.metadata.clear -eq 'True'
	[bool]$includeBinary = $config.package.metadata.includeBinary -eq 'True'
	[bool]$includeContent = $config.package.metadata.includeContent -eq 'True'

	pushd $slnFolder

	$csProject = @{}
	Get-CSharpProjects -SolutionPath $slnPath | % {
		$csProject[$_.Project] = "$slnFolder\$($_.ProjectPath)"
	}

	$dbProject = @{}
	Get-SqlProjects -SolutionPath $slnPath | % {
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
		$config.package.metadata.projects.netProject | % {
			$projName = $_
			if ($csProject.ContainsKey($projName)) {
				$projPath = $csProject[$projName]
				$projFolder = Split-Path $projPath
				$projBinFolder = "$projFolder\bin\$buildConfig"

				Import-ArtifactProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -ArtifactBinFolder $releaseBinFolder -DefaultAssemblyName $projName
				move $releaseBinFolder\content\* $releaseBinFolder\ -Force
				rmdir $releaseBinFolder\content
			} else {
				throw "Project $projName is not in the solution"
			}
		}
	}

	if ($includeContent) {
		copy $contentFolder\* $releaseContentFolder\ -Recurse -Force
		$config.package.metadata.projects.netProject | % {
			$projName = $_
			if ($csProject.ContainsKey($projName)) {
				$projPath = $csProject[$projName]
				$projFolder = Split-Path $projPath
				$projContentFolder = "$projFolder\$content"
				if (Test-Path $projContentFolder) {
					copy $projContentFolder\* $releaseContentFolder\ -Recurse -Force
				}
			}
		}
	}

	if (Test-Path "$slnFolder\Databases") {
		copy "$slnFolder\**\Databases\*" $releaseDbFolder\ -Recurse -Force
		copy "$slnFolder\Databases\*" $releaseDbFolder\ -Recurse -Force
	}

	$contentFolders | % {
		if (Test-Path "$slnFolder\$_") {
			if (-not (Test-Path "$releaseFolder\$_")) {
				mkdir "$releaseFolder\$_"
			}
			copy "$slnFolder\$_\*" "$releaseFolder\$_\" -Recurse -Force
		}
	}
	$contentFiles | % {
		if (Test-Path "$slnFolder\$_") {
			copy "$slnFolder\$_" $releaseFolder -Force
		}
	}

	$config.package.metadata.projects.dbProject | % {
		$projName = $_
		if ($dbProject.ContainsKey($projName)) {
			$projPath = $dbProject[$projName]
			$projFolder = Split-Path $projPath
			copy "$projFolder\Databases\*" $releaseDbFolder\ -Recurse
			copy "$projFolder\*.publish.xml" $releaseDbFolder\
		} else {
			throw "Database project $projName is not in the solution"
		}
	}

} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host $_.Exception.StackTrace
	Exit 1
} finally {
	popd
}
