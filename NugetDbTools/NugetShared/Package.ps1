$id='NuGetShared'
$contentType='PowerShell'
$projDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
$slnDir = "$projDir\.."
pushd $projDir


$loaded = $false
if (-not (Get-Module NugetShared)) {
	$loaded = $true
	Import-Module ".\bin\Debug\$id\NugetShared.psm1"
}

$version = Set-NuspecVersion -Path Package.nuspec -ProjectFolder $projDir

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet | Out-Null
cd NuGet
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $_ | Out-Null }
cd ..
copy "bin\Debug\$id\$id.ps*1" "NuGet\content\$contentType\"

if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
	NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
	nuget push "$projDir\$id.$version.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)
}

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$version.nupkg"
if ($loaded) {
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
