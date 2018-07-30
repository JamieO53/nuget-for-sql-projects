$id='GitExtension'
$contentType='PowerShell'
$projDir = (Get-Item "$(Split-Path -Path $MyInvocation.MyCommand.Path)").FullName
$slnDir = (Get-Item "$projDir\..\..").FullName
pushd $projDir
try {

	$loaded = $false
	if (-not (Get-Module NugetSharedPacker)) {
		$loaded = $true
		Import-Module "$slnDir\NugetSharedPacker\bin\Debug\NugetSharedPacker\NugetSharedPacker.psd1"
	}

	$version = Set-NuspecVersion -Path Package.nuspec -ProjectFolder $projDir
	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

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
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	popd
}