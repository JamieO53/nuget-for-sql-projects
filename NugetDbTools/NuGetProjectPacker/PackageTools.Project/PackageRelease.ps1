$projectType = 'Release'

try {
	$slnDir = (Get-Item "$PSScriptRoot").FullName
	$releaseFolder = "$slnDir\Release"
	$releaseBinFolder = "$releaseFolder\lib"
	$releaseDbFolder = "$releaseFolder\db"
	$releaseConfigPath = "$slnDir\PackageRelease.config"
	pushd $slnDir

	$loaded = $false
	if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
		Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psm1"
}

	[xml]$config = gc $releaseConfigPath
	$id = $config.package.metadata.id
	$oldVersion = $config.package.metadata.version
	$version = Measure-ProjectVersion -Path $Path -ProjectFolder $slnDir -OldVersion $oldVersion -UpVersion $false
	$description = $config.package.metadata.description

	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

	Set-NodeText -parentNode $config.package.metadata -id version -text $version
	Out-FormattedXml -Xml $config -FilePath $releaseConfigPath

	if (Test-Path $releaseFolder) {
		del $releaseFolder\* -Recurse -Force
		rmdir $releaseFolder
	}

	md "$releaseFolder" | Out-Null
	'lib', 'db' | % { mkdir $releaseFolder\$_ | Out-Null }

	$config.package.metadata.projects.netProject | % {
		[string]$projSubPath = $_
		$projName = Split-Path $projSubPath -Leaf
		$projDir = "$slnDir\$projName"
		$projPath = "$projDir\$projName.csproj"
		$projBinFolder = "$projDir\bin\Debug"
	
		Import-ArtifactProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -ArtifactBinFolder $releaseBinFolder -DefaultAssemblyName $projName
	}

	if (Test-Path "$slnDir\Databases") {
		copy "$slnDir\Databases\*" $releaseDbFolder -Recurse
	}

	$config.package.metadata.projects.dbProject | % {
		[string]$projSubPath = $_
		$projName = Split-Path $projSubPath -Leaf
		$projDir = "$slnDir\$projSubPath"
		copy "$projDir\Databases\*" $releaseDbFolder -Recurse
		'release','prod','uat' |
		% { ls "$projDir\*.$_.publish.xml" | select -First 1 | % { $_.FullName } |
			? { Test-Path $_ } |
			% {
				copy $_ $releaseDbFolder
			}
		}
	}

	if (-not (Test-UniversalVersionExists -Id $id -Version $version)){
	    Publish-UniversalPackage -PackageFolder $releaseFolder -PackageName $id -PackageVersion $version -PackageDescription $description
	}

	Remove-NugetFolder $releaseFolder
	if ($loaded) {
		Remove-Module NuGetProjectPacker -ErrorAction Ignore
	}
} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	popd
}
