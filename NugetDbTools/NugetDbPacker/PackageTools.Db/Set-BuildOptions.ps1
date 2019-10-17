sqllocaldb create ecentric

if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module "$PSScriptRoot\..\PowerShell\NugetSharedPacker.psd1" -Global -DisableNameChecking
}
$slnFolder = Get-ParentSubFolder "$PSScriptRoot" '*.sln'
$slnPath = Get-ChildItem "$slnFolder\*.sln" | Select-Object -First 1 | ForEach-Object { $_.FullName }
$nuspecPath = "$slnFolder\Package.nuspec"

if (Test-Path $nuspecPath) {
	$versionBranch = (Set-NuspecVersion -Path  $nuspecPath -ProjectFolder $slnFolder).Split('-',2)
	$version = $versionBranch[0]
	if ($versionBranch.Count -eq 2) {
		$version += '.0'
	}
	$regex = '(Assembly.*Version\(\")([\d\.]*)(\"\))'
	Get-CSharpProjects $slnPath | ForEach-Object {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$infoPath = "$projFolder\Properties\AssemblyInfo.cs"
		if (Test-Path $infoPath) {
			$info = Get-Content $infoPath
			$info = $info -replace $regex,"`${1}$version`${3}"
			$info | Out-File $infoPath
		}
		[xml]$proj = Get-Content -Path $projPath
		$parentNode = $proj.Project.PropertyGroup | Where-Object { $_.ApplicationVersion }
		if ($parentNode) {
			Set-NodeText -parentNode $parentNode -id 'ApplicationVersion' -text $version
			Out-FormattedXml -Xml $proj -FilePath $projPath
		}
	}
}
