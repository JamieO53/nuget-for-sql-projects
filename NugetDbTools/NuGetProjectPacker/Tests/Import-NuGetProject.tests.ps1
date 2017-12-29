if ( Get-Module NugetBinPacker) {
	Remove-Module NugetBinPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetBinPacker\NugetBinPacker.psm1"
Describe "Import-NuGetProject" {
	$projFolder = "TestDrive:\proj"
	$projBinFolder = "$projFolder\bin\"
	$projPath = "$projFolder\proj.csproj"
	$nugetFolder = "$projFolder\NuGet"
	$nugetBinFolder = "$nugetFolder\lib\net451"
	$nugetSpecPath = "$nugetFolder\Package.nuspec"
	$nugetSettings = Initialize-TestNugetConfig
	$projText = @"
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <Import Project="$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props" Condition="Exists('$(MSBuildExtensionsPath)\$(MSBuildToolsVersion)\Microsoft.Common.props')" />
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProjectGuid>{963C72B7-4A4E-4BF7-8455-498C692E18EE}</ProjectGuid>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>Ecentric.Triton</RootNamespace>
    <AssemblyName>Ecentric.Triton</AssemblyName>
    <TargetFrameworkVersion>v4.5.1</TargetFrameworkVersion>
    <FileAlignment>512</FileAlignment>
    <TargetFrameworkProfile />
  </PropertyGroup>
</Project>
"@
	Context "Files setting in nuget spec" {
		mkdir $projBinFolder
		$projText | Set-Content $projPath
		'lib' | Set-Content "$projBinFolder\ProjLib.dll"
		'pdb' | Set-Content "$projBinFolder\ProjLib.pdb"
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -NugetSpecPath $nugetSpecPath
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
		mkdir $projBinFolder
		$projText | Set-Content $projPath
		'lib' | Set-Content "$projBinFolder\ProjLib.dll"
		'pdb' | Set-Content "$projBinFolder\ProjLib.pdb"
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Import-NuGetDb -ProjectPath $projPath -ProjBinFolder $projBinFolder -NugetBinFolder $nugetBinFolder -NugetSpecPath $nugetSpecPath
		
		It "Lib imported" { Test-Path "$nugetBinFolder\ProjLib.dll" | should be $true }
		It "Pdb imported" { Test-Path "$nugetBinFolder\ProjLib.pdb" | should be $true }
		Remove-Item -Path $projFolder -Recurse -Force
	}
}