$id='NuGetDbPacker.DbTemplate'
$contentType='Template'
$slnDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)"
pushd $slnDir

[xml]$cfg = gc Package.nuspec
$version=$cfg.package.metadata.version

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet
cd NuGet
'tools','lib',"content\CiTools","content\$contentType\Template.DBProject","content\$contentType\Template.DBPkg",'build' | % { md $_ }
cd ..
copy "$slnDir\CiTools\Bootstrap.*" "NuGet\content\$contentType\CiTools\"
copy "$slnDir\*.sln" "NuGet\content\$contentType\"
copy "$slnDir\Template.DBProject\*" "NuGet\content\$contentType\Template.DBProject\" -Exclude @('bin','obj','*.user')
copy "$slnDir\Template.DBPkg\*" "NuGet\content\$contentType\Template.DBPkg\" -Exclude @('bin','obj','*.user')

NuGet pack -BasePath NuGet
nuget push "$id.$version.nupkg" NUG3TK3Y -Source 'http://srv103octo01:808/NugetServer/nuget'

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$version.nupkg"
popd
