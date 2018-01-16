if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"
if (-not (Get-Module TestUtils)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1"
}
Describe "Import-NuGetDb" {
	$projFolder = "TestDrive:\proj"
	$projDbFolder = "$projFolder\Databases"
	$projPath = "$projFolder\proj.sqlproj"
	$nugetFolder = "$projFolder\NuGet"
	$nugetDbFolder = "$nugetFolder\content\Databases"
	$nugetSpecPath = "$nugetFolder\Package.nuspec"
	$nugetSettings = Initialize-TestNugetConfig
	$projText = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<Project DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`" ToolsVersion=`"4.0`">
  <PropertyGroup>
    <DacApplicationName>ProjDb</DacApplicationName>
  </PropertyGroup>
  <PropertyGroup>
    <Configuration Condition=`" '`$(Configuration)' == '' `">Debug</Configuration>
    <AssemblyName>ProjLib</AssemblyName>
  </PropertyGroup>
</Project>
"@
	Context "Files setting in nuget spec" {
		mkdir $projDbFolder
		$projText | Set-Content $projPath
		'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
		'lib' | Set-Content "$projDbFolder\ProjLib.dll"
		'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjDbFolder $projDbFolder -NugetDbFolder $nugetDbFolder -NugetSpecPath $nugetSpecPath
		[xml]$spec = gc "$nugetFolder\Package.nuspec"

		It "Files group should exist" { $spec.package.SelectNodes('files') | should not BeNullOrEmpty }
		It "File node should exist" { $spec.package.files.SelectNodes('file') | should not BeNullOrEmpty }
		Context "File node content" {
			$fileNode = $spec.package.files.SelectSingleNode('file')
			It "Source" { $fileNode.src | should be 'content\Databases\**' }
			It "Target" { $fileNode.target | should be 'Databases' }
		}

		Remove-Item -Path $projFolder -Recurse -Force
	}
	Context "Import project build files" {
		mkdir $projDbFolder
		$projText | Set-Content $projPath
		'dacpac' | Set-Content "$projDbFolder\ProjDb.dacpac"
		'lib' | Set-Content "$projDbFolder\ProjLib.dll"
		'pdb' | Set-Content "$projDbFolder\ProjLib.pdb"
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjDbFolder $projDbFolder -NugetDbFolder $nugetDbFolder -NugetSpecPath $nugetSpecPath
		
		It "Dacpac imported" { Test-Path "$nugetDbFolder\ProjDb.dacpac" | should be $true }
		It "Lib imported" { Test-Path "$nugetDbFolder\ProjLib.dll" | should be $true }
		It "Pdb imported" { Test-Path "$nugetDbFolder\ProjLib.pdb" | should be $true }
		Remove-Item -Path $projFolder -Recurse -Force
	}
}