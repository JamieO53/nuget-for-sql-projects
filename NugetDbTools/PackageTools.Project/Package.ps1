$id='Triton'
$contentType='lib'
$projDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
$slnDir = (Get-Item "$projDir\..").FullName
pushd $projDir


$loaded = $false
if (-not (Get-Module NuGetProjectPacker)) {
	$loaded = $true
	Import-Module "$slnDir\PowerShell\NuGetProjectPacker.psd1"
}

$version = Set-NuspecVersion -Path $projDir\Package.nuspec -ProjectFolder $projDir
#Set-NuspecDependencyVersion -Path $projDir\Package.nuspec -Dependency 'NuGetShared'

if (Test-Path $projDir\NuGet) {
	del $projDir\NuGet\* -Recurse -Force
	rmdir $projDir\NuGet
}

md "$projDir\NuGet" | Out-Null
'tools','lib',"content\$contentType","content\PackageTools",'build' | % { md $projDir\NuGet\$_ | Out-Null }

Import-NuGetProject -ProjectPath $projDir\$id.csproj -ProjBinFolder $projDir\bin\Debug -NugetBinFolder $projDir\NuGet\lib -NugetSpecPath $projDir\Package.nuspec

NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
nuget push "$projDir\$id.$version.nupkg" (Get-NuGetLocalApiKey) -Source (Get-NuGetLocalSource)

del $projDir\NuGet\* -Recurse -Force
rmdir $projDir\NuGet
del "$projDir\$id.$version.nupkg"
if ($loaded) {
	Remove-Module NuGetProjectPacker -ErrorAction Ignore
	Remove-Module NugetShared -ErrorAction Ignore
}
popd
