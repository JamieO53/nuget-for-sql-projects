$id='NuGetShared'
$contentType='PowerShell'
$projDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)"
$slnDir = "$projDir\.."
pushd $projDir

[xml]$cfg = gc Package.nuspec
$version=$cfg.package.metadata.version

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet
cd NuGet
'tools','lib',"content\$contentType","content\CiTools",'build' | % { md $_ }
cd ..
copy "bin\Debug\$id\$id.ps*1" "NuGet\content\$contentType\"
copy "$slnDir\CiTools\*" "NuGet\content\CiTools\"

NuGet pack -BasePath NuGet
nuget push "$id.$version.nupkg" NUG3TK3Y -Source 'http://srv103octo01:808/NugetServer/nuget'

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$version.nupkg"
popd
