$projectType = 'Project'
$projName='Name'
$id="JamieO53.$projName"
$contentType='lib'
$buildConfig='Debug'

try {
	$slnDir = (Get-Item "$PSScriptRoot").FullName
	$slnPath = Get-ChildItem "$slnDir\*.sln" | Select-Object -First 1 | ForEach-Object { $_.FullName }

	$nugetFolder = "$slnDir\NuGet"
	$nuspecPath = "$slnDir\Package.nuspec"
	$nugetBinFolder = "$nugetFolder\$contentType"
	Push-Location $slnDir

	$loaded = $false
	if (-not (Get-Module NuGetProjectPacker)) {
		$loaded = $true
		Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psm1" -Global -DisableNameChecking
	}

	$project = @{}
	Get-CSharpProjects -SolutionPath $slnPath | ForEach-Object {
		$project[$_.Project] = "$slnDir\$($_.ProjectPath)"
	}

	$version = Set-NuspecVersion -Path $nuspecPath -ProjectFolder $slnDir
	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

	$nugetPackagePath = "$slnDir\$id.$version.nupkg"

	if (Test-Path $nugetFolder) {
		Remove-NugetFolder $nugetFolder
	}

	Initialize-NuGetFolders -Path $nugetFolder
	'lib' | ForEach-Object { mkdir $nugetFolder\$_ | Out-Null }

	('Project1','Project2','Project3','Project4', 'Project5') | ForEach-Object {
		$projName = $_
		if ($project.ContainsKey($projName)) {
			$projPath = $project[$projName]
			$projDir = Split-Path $projPath
			$projBinFolder = "$projDir\bin\$buildConfig"

			Initialize-NuGetRuntime -ProjectPath $projPath -SolutionPath $slnPath -Path $nugetFolder
			Import-ArtifactProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -ArtifactBinFolder $nugetBinFolder -DefaultAssemblyName $projName
		} else {
			Write-Host "Project $projName is not in the solution"
			Exit 1
		}
	}

	if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
		Compress-Package -NuspecPath $nuspecPath -NugetFolder $nugetFolder -PackageFolder $slnDir
		if ($env:USERNAME -EQ 'Builder') {
			Publish-NuGetPackage -PackagePath $nugetPackagePath
			Remove-NugetFolder $nugetFolder
		}
	}

	if ($loaded) {
		Remove-Module NuGetProjectPacker -ErrorAction Ignore
	}
} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	Pop-Location
}