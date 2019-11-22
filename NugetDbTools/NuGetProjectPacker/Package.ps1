param (
	[bool]$upVersion = $false
)
$cfg = Import-PowerShellDataFile "$(Split-Path -Path $MyInvocation.MyCommand.Path)\BuildConfig.psd1"

$id = $cfg.ProjectName

$projectType = $cfg.ProjectType
$contentType='PowerShell'
$dependencies=$cfg.Dependencies
$extensions=$cfg.Extensions
$projDir = (Get-Item "$(Split-Path -Path $MyInvocation.MyCommand.Path)").FullName
$slnDir = (Get-Item "$projDir\..").FullName

Push-Location $projDir
try {

	$loaded = $false
	if (-not (Get-Module NugetSharedPacker)) {
		$loaded = $true
		Import-Module "$slnDir\NugetSharedPacker\bin\Debug\NugetSharedPacker\NugetSharedPacker.psd1" -Global -DisableNameChecking
	}

	$branch = Get-Branch
	$version = Set-NuspecVersion -Path $projDir\Package.nuspec -ProjectFolder $projDir -UpVersion $upVersion
	if ($version -like '*.0'){
		throw "Invalid version $version"
	}

	$dependencies | ForEach-Object {
		Set-NuspecDependencyVersion -Path $projDir\Package.nuspec -Dependency $_ -Branch $branch
	}

	if (Test-Path $projDir\NuGet) {
		Remove-Item $projDir\NuGet\* -Recurse -Force
		Remove-Item $projDir\NuGet
	}

	mkdir "$projDir\NuGet" | Out-Null
	'content\PackageTools', "content\$contentType" | ForEach-Object { mkdir $projDir\NuGet\$_ | Out-Null }

	Copy-Item "bin\Debug\$id\$id.ps*1" "NuGet\content\$contentType\"
	$extensions | ForEach-Object {
		Copy-Item "bin\Debug\$id\$_.ps*1" "NuGet\content\$contentType\"
	}
	if ($projectType){
		Copy-Item "$slnDir\PackageTools\*" "$projDir\NuGet\content\PackageTools\"
		Copy-Item "$projDir\PackageTools.$projectType\*" "$projDir\NuGet\content\PackageTools\" -Force
		"powershell -Command `".\Bootstrap.ps1`" -ProjectType $projectType" |
			Set-Content "$projDir\NuGet\content\PackageTools\Bootstrap.cmd" -Encoding Ascii
	}

	if (Test-Path "NuGet\content\$contentType\$id.psd1") {
		$lines = Get-Content "NuGet\content\$contentType\$id.psd1" | ForEach-Object {
			if ( $_.StartsWith('ModuleVersion = ')) {
				$moduleVersion = $version.Split('-')[0]
				"ModuleVersion = '$moduleVersion'"
			} else {
				$_
			}
		}
		$lines | Set-Content "NuGet\content\$contentType\$id.psd1"
	}

	if ($upVersion) {
		Update-ToRepository -Path $projDir\Package.nuspec -Message 'BATCH update dependency versions'
	}

	if (-not (Test-NuGetVersionExists -Id $id -Version $version)){
		NuGet pack $projDir\Package.nuspec -BasePath "$projDir\NuGet" -OutputDirectory $projDir
		Publish-NuGetPackage -PackagePath "$projDir\$id.$version.nupkg"
	}

	Remove-NugetFolder $projDir\NuGet
	if (Test-Path "$projDir\$id.$version.nupkg")
	{
		Remove-Item "$projDir\$id.$version.nupkg"
	}
	if ($loaded) {
		Remove-Module NugetShared -ErrorAction Ignore
	}
} catch {
	Write-Host "$id packaging failed: $($_.Exception.Message)" -ForegroundColor Red
	Exit 1
} finally {
	Pop-Location
}