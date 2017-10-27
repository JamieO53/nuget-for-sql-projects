$id='NuGetDbPacker'
$contentType='PowerShell'
$projDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)"
$slnDir = "$projDir\.."
pushd $projDir


$loaded = $false
if (-not (Get-Module NugetShared)) {
	$loaded = $true
	Import-Module "bin\Debug\$id\NugetShared.ps1"
}

$version = Set-NuspecVersion -Path Package.nuspec

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet | Out-Null
cd NuGet
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $_ | Out-Null }
cd ..
copy "bin\Debug\$id\$id.ps*1" "NuGet\content\$contentType\"
copy "$slnDir\PackageTools\*" "NuGet\content\PackageTools\"

NuGet pack -BasePath NuGet
nuget push "$id.$version.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$version.nupkg"
if ($loaded) {
	Remove-Module NugetShared
}
popd
