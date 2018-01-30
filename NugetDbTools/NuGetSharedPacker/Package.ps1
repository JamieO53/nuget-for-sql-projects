$id='NuGetSharedPacker'
$contentType='PowerShell'
$projDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)").Path
$slnDir = "$projDir\.."
pushd $projDir
try {

	$loaded = $false
	if (-not (Get-Module NugetShared)) {
		$loaded = $true
		Import-Module "$projDir\bin\Debug\$id\NugetShared.psm1"
	}

	$version = Set-NuspecVersion -Path $projDir\Package.nuspec -ProjectFolder $projDir
	if ($version -like '*.0'){
		throw "Invalid version"
	}

	Set-NuspecDependencyVersion -Path $projDir\Package.nuspec -Dependency 'NuGetShared'

	if (Test-Path $projDir\NuGet) {
		del $projDir\NuGet\* -Recurse -Force
		rmdir $projDir\NuGet
	}

	md "$projDir\NuGet" | Out-Null
	'tools','lib',"content\$contentType","content\PackageTools",'build' | % { mkdir $projDir\NuGet\$_ | Out-Null }

	copy "bin\Debug\$id\$id.ps*1" "NuGet\content\$contentType\"

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
} catch {
	Write-Error "$id packaging failed: $($_.Message)"
	Exit 1
}
} finally {
	popd
}