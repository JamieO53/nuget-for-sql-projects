$projectType = 'Project'
$projName='ProjectName'
$id="Prefix.$projName"
$contentType='lib'

try {
	$projDir = (Get-Item "$(Split-Path -Path $MyInvocation.MyCommand.Path)").FullName
	$slnDir = (Get-Item "$projDir\..").FullName
	$projPath = "$projDir\$projName.csproj"
	$projBinFolder = "$projDir\bin\Debug"
	$nugetFolder = "$projDir\NuGet"
	$nuspecPath = "$projDir\Package.nuspec"
	$nugetBinFolder = "$nugetFolder\$contentType"
	pushd $projDir

	$loaded = $false
	if (-not (Get-Module NuGetProjectPacker)) {
		$loaded = $true
		Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psm1"
	}

	$version = Set-NuspecVersion -Path $projDir\Package.nuspec -ProjectFolder $projDir
	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

	$nugetPackagePath = "$projDir\$id.$version.nupkg"

	if (Test-Path $projDir\NuGet) {
		del $projDir\NuGet\* -Recurse -Force
		rmdir $projDir\NuGet
	}

	md "$projDir\NuGet" | Out-Null
	'content\PackageTools', "content\$contentType" | % { mkdir $projDir\NuGet\$_ | Out-Null }

	Import-NuGetProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -DefaultAssemblyName $projName

	if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
		NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
		Publish-NuGetPackage -PackagePath $nugetPackagePath
	}

	Remove-NugetFolder $projDir\NuGet
	if (Test-Path $nugetPackagePath)
	{
		del $nugetPackagePath
	}
	if ($loaded) {
		Remove-Module NuGetProjectPacker -ErrorAction Ignore
	}
} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	popd
}