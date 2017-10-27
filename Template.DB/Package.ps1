$id='NuGetDbPacker.DbTemplate'
$contentType='Template'
$slnDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)"
pushd $slnDir

if (-not (Get-Module NuGetShared))
{
	Import-Module ..\NugetDbTools\NuGetShared\bin\Debug\NuGetShared\NuGetShared.psd1
}

[xml]$cfg = gc Package.nuspec
$oldVersion=$cfg.package.metadata.version
$versionParts = $oldVersion.Split('.')
$majorVersion = $versionParts[0]
$minorVersion = $versionParts[1]
$newVersion = Get-ProjectVersion -Path $slnDir -MajorVersion $majorVersion -MinorVersion $minorVersion
$cfgText = gc Package.nuspec | Out-String
$cfgText =  $cfgText.Replace($oldVersion, $newVersion).TrimEnd()
$cfgText | Out-File -FilePath .\Package.nuspec -Encoding utf8 -Force

if (Test-Path NuGet) {
	del NuGet\* -Recurse -Force
	rmdir NuGet
}
md NuGet | Out-Null
cd NuGet
'tools','lib',"content\$contentType\PackageTools","content\$contentType\Template.DBProject","content\$contentType\Template.DBPkg",'build' | % { md $_ | Out-Null }
cd ..
copy "$slnDir\PackageTools\Bootstrap.*" "NuGet\content\$contentType\PackageTools\"
copy "$slnDir\*.sln" "NuGet\content\$contentType\"
copy "$slnDir\Template.DBProject\*" "NuGet\content\$contentType\Template.DBProject\" -Exclude @('bin','obj','*.user','*.dbmdl','*.jfm')
copy "$slnDir\Template.DBPkg\*" "NuGet\content\$contentType\Template.DBPkg\" -Exclude @('bin','obj','*.user')

NuGet pack -BasePath NuGet
nuget push "$id.$newVersion.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)

del NuGet\* -Recurse -Force
rmdir NuGet
del "$id.$newVersion.nupkg"
popd
