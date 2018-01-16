$id='NuGetDbPacker.DbTemplate'
$contentType='Template'
$slnDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
pushd $slnDir

$loaded = $false
if (-not (Get-Module NuGetShared)) {
	$loaded = $true
	Import-Module $slnDir\..\NugetDbTools\NuGetShared\bin\Debug\NuGetShared\NuGetShared.psd1
}

$version = Set-NuspecVersion -Path $slnDir\Package.nuspec -ProjectFolder $slnDir

if (Test-Path $slnDir\NuGet) {
	del $slnDir\NuGet\* -Recurse -Force
	rmdir $slnDir\NuGet
}
md $slnDir\NuGet | Out-Null
cd $slnDir\NuGet
'tools','lib',"content\PackageTools","content\$contentType\Template.DBProject","content\$contentType\Template.DBPkg",'build' | % { md $_ | Out-Null }
cd ..
copy "$slnDir\PackageTools\Bootstrap.*" "NuGet\content\PackageTools\"
copy "$slnDir\*.sln" "NuGet\content\$contentType\"
copy "$slnDir\Template.DBProject\*" "NuGet\content\$contentType\Template.DBProject\" -Exclude @('bin','obj','*.user','*.dbmdl','*.jfm')
copy "$slnDir\Template.DBPkg\*" "NuGet\content\$contentType\Template.DBPkg\" -Exclude @('bin','obj','*.user')

NuGet pack -BasePath "$slnDir\NuGet"
Publish-NuGetPackage -PackagePath "$slnDir\$id.$version.nupkg"

del $slnDir\NuGet\* -Recurse -Force
rmdir $slnDir\NuGet
del "$slnDir\$id.$version.nupkg"
if ($loaded) {
	Remove-Module NugetShared
}
popd
