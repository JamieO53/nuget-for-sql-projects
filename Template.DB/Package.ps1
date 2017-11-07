$id='NuGetDbPacker.DbTemplate'
$contentType='Template'
$slnDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)"
pushd $slnDir

$loaded = $false
if (-not (Get-Module NuGetShared)) {
	$loaded = $true
	Import-Module ..\NugetDbTools\NuGetShared\bin\Debug\NuGetShared\NuGetShared.psd1
}

$version = Set-NuspecVersion -Path Package.nuspec -ProjectFolder $slnDir

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet | Out-Null
cd NuGet
'tools','lib',"content\PackageTools","content\$contentType\Template.DBProject","content\$contentType\Template.DBPkg",'build' | % { md $_ | Out-Null }
cd ..
copy "$slnDir\PackageTools\Bootstrap.*" "NuGet\content\PackageTools\"
copy "$slnDir\*.sln" "NuGet\content\$contentType\"
copy "$slnDir\Template.DBProject\*" "NuGet\content\$contentType\Template.DBProject\" -Exclude @('bin','obj','*.user','*.dbmdl','*.jfm')
copy "$slnDir\Template.DBPkg\*" "NuGet\content\$contentType\Template.DBPkg\" -Exclude @('bin','obj','*.user')

NuGet pack -BasePath NuGet
nuget push "$id.$version.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$version.nupkg"
if ($loaded) {
	Remove-Module NugetShared
}
popd
