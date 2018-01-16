$id='Triton'
$contentType='lib'
$projDir = Split-Path $MyInvocation.MyCommand.Path
$projPath = "$projDir\$id.csproj"
$nuspecPath = "$projDir\$id.nuspec"
$nugetFolder = "$projDir\NuGet"
$slnDir = (Get-Item "$projDir\..").FullName
$projBinFolder = "$projDir\bin\Debug"
$nugetBinFolder = "$nugetFolder\Lib"
pushd $projDir


$loaded = $false
if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
	Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psd1"
}

Initialize-NuGetFolders -Path $nugetFolder
$spec = Import-NugetSettingsFramework -ProjectPath $projPath
$version = Set-NuspecVersion -Path $nuspecPath -ProjectFolder $projDir

if (Test-Path $projDir\NuGet) {
	del $projDir\NuGet\* -Recurse -Force
	rmdir $projDir\NuGet
}

md "$projDir\NuGet" | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $projDir\NuGet\$_ | Out-Null }
$nugetSettings = Import-NugetSettingsFramework -ProjectPath $projPath
Initialize-NuGetFolders -Path $nugetFolder
Initialize-NuGetSpec -Path $projDir -setting $nugetSettings

Import-NuGetProject -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -NugetSpecPath $projDir\Package.nuspec

if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
    NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
    Publish-NuGetPackage -PackagePath "$projDir\$id.$version.nupkg"
}

del $projDir\NuGet* -Recurse -Force
if (Test-Path "$projDir\$id.$version.nupkg")
{
	del "$projDir\$id.$version.nupkg"
}
if ($loaded) {
	Remove-Module NuGetProjectPacker -ErrorAction Ignore
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
