$projectType = 'Db'
$id="NuGet$($projectType)Packer"
$contentType='PowerShell'
$projDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
$slnDir = "$projDir\.."
pushd $projDir


$loaded = $false
if (-not (Get-Module NugetShared)) {
	$loaded = $true
	Import-Module "$projDir\bin\Debug\$id\NugetShared.psm1"
}

$version = Set-NuspecVersion -Path Package.nuspec -ProjectFolder $projDir

Set-NuspecDependencyVersion -Path $projDir\Package.nuspec -Dependency 'NuGetSharedPacker'

if (Test-Path $projDir\NuGet) {
	del $projDir\NuGet\* -Recurse -Force
	rmdir $projDir\NuGet
}

md "$projDir\NuGet" | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { mkdir $projDir\NuGet\$_ | Out-Null }

copy "$projDir\bin\Debug\$id\$id.ps*1" "$projDir\NuGet\content\$contentType\"
copy "$slnDir\PackageTools\*" "$projDir\NuGet\content\PackageTools\"
copy "$slnDir\PackageTools.$projectType\*" "$projDir\NuGet\content\PackageTools\"
"powershell -Command `".\Bootstrap.ps1`" -ProjectType $projectType" |
	Set-Content "$projDir\NuGet\content\PackageTools\Bootstrap.cmd" -Encoding Ascii

if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
	NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
	Publish-NuGetPackage -PackagePath "$projDir\$id.$version.nupkg"
}

Remove-NugetFolder $projDir\NuGet
if (Test-Path "$projDir\$id.$version.nupkg")
{
	del "$projDir\$id.$version.nupkg"
}
if ($loaded) {
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
