$id='Dummy.Ethel'
$contentType='lib'
$slnDir = Split-Path $MyInvocation.MyCommand.Path
$nuspecPath = "$slnDir\Package.nuspec"
$pkgCfgPath = "$slnDir\EthelCore\packages.config"
$nugetFolder = "$slnDir\NuGet"
$nugetPackagePath = "$slnDir\$id.$version.nupkg"
$nugetBinFolder = "$nugetFolder\Lib"
$pkgPath = "$slnDir\$id.$version.nupkg"
pushd $slnDir

$loaded = $false
if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
	Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psd1"
}

if (Test-Path $nugetFolder) {
	del $nugetFolder\* -Recurse -Force
	rmdir $nugetFolder
}

md $nugetFolder | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $nugetFolder\$_ | Out-Null }
$version = Set-NuspecVersion -Path $nuspecPath -ProjectFolder $slnDir
$nugetSettings = Import-NugetSettingsFramework -NuspecPath $nuspecPath -PackagesConfigPath $pkgCfgPath
Initialize-NuGetSpec -Path $slnDir -setting $nugetSettings

('Ethel','ETLCore','ETLCmd','ETLCmdEditor', 'FilePager') | % {
	$projName = $_
	$projDir = "$slnDir\$projName"
	$projPath = "$projDir\$projName.csproj"
	$projBinFolder = "$slnDir\$projName\bin\Debug"
	
	Import-NuGetProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -NugetSpecPath $nuspecPath
}

if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
    NuGet pack $nuspecPath -BasePath "$nugetFolder" -OutputDirectory $slnDir
    Publish-NuGetPackage -PackagePath $nugetPackagePath
}

del $nugetFolder\* -Recurse -Force
rmdir $nugetFolder
if (Test-Path $nugetPackagePath)
{
	del $nugetPackagePath
}
if ($loaded) {
	Remove-Module NuGetProjectPacker -ErrorAction SilentlyContinue
	Remove-Module NugetSharedPacker -ErrorAction SilentlyContinue
	Remove-Module NugetShared -ErrorAction SilentlyContinue
}
popd
