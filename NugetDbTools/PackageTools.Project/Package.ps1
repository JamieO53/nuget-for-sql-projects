$id='Dummy.Triton'
$projName='Triton'
$contentType='lib'
$projDir = Split-Path $MyInvocation.MyCommand.Path
$projPath = "$projDir\$projName.csproj"
$nuspecPath = "$projDir\Package.nuspec"
$pkgCfgPath = "$projDir\packages.config"
$nugetFolder = "$projDir\NuGet"
$slnDir = (Get-Item "$projDir\..").FullName
$projBinFolder = "$projDir\bin\Debug"
$nugetBinFolder = "$nugetFolder\Lib"
pushd $projDir


$loaded = $false
if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
	Import-Module "$slnDir\PowerShell\NuGetShared.psd1"
	Import-Module "$slnDir\PowerShell\NuGetSharedPacker.psd1"
	Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psd1"
}

if (Test-Path $nugetFolder) {
	del $nugetFolder\* -Recurse -Force
	rmdir $nugetFolder
}

md $nugetFolder | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $nugetFolder\$_ | Out-Null }
$nugetSettings = Import-NugetSettingsFramework -NuspecPath $nuspecPath -PackagesConfigPath $pkgCfgPath
$version = Set-NuspecVersion -Path $nuspecPath -ProjectFolder $projDir
$pkgPath = "$projDir\$id.$version.nupkg"
Initialize-NuGetFolders -Path $nugetFolder
Initialize-NuGetSpec -Path $projDir -setting $nugetSettings

Import-NuGetProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -NugetSpecPath $nuspecPath

if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
    NuGet pack $nuspecPath -BasePath $nugetFolder -OutputDirectory $projDir
    Publish-NuGetPackage -PackagePath $pkgPath
}

del $nugetFolder\* -Recurse -Force
rmdir $nugetFolder
if (Test-Path $pkgPath)
{
	del $pkgPath
}

if ($loaded) {
	Remove-Module NuGetProjectPacker -ErrorAction Ignore
	Remove-Module NugetSharedPacker -ErrorAction Ignore
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
