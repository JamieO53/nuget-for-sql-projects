if ( Get-Module NuGetProjectPacker) {
	Remove-Module NuGetProjectPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetProjectPacker\NuGetProjectPacker.psm1" -Global -DisableNameChecking

$projText = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<Project ToolsVersion=`"12.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">
  <Import Project=`"`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props`" Condition=`"Exists('`$(MSBuildExtensionsPath)\`$(MSBuildToolsVersion)\Microsoft.Common.props')`" />
  <PropertyGroup>
    <Configuration Condition=`" '`$(Configuration)' == '' `">Debug</Configuration>
    <Platform Condition=`" '`$(Platform)' == '' `">AnyCPU</Platform>
    <ProjectGuid>{963C72B7-4A4E-4BF7-8455-498C692E18EE}</ProjectGuid>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>ProjLib</RootNamespace>
    <AssemblyName>ProjLib</AssemblyName>
    <TargetFrameworkVersion>v4.5.1</TargetFrameworkVersion>
    <FileAlignment>512</FileAlignment>
    <TargetFrameworkProfile />
  </PropertyGroup>
</Project>
"@
$pkgCfgText = @'
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Autofac" version="3.3.1" targetFramework="net451" />
  <package id="Autofac.Mef" version="4.0.0" targetFramework="net451" />
  <package id="Autofac.Wcf" version="4.0.0" targetFramework="net451" />
  <package id="Newtonsoft.Json" version="6.0.8" targetFramework="net451" />
  <package id="NLog" version="4.3.11" targetFramework="net451" />
  <package id="System.Reactive.Core" version="3.1.1" targetFramework="net451" />
  <package id="System.Reactive.Interfaces" version="3.1.1" targetFramework="net451" />
  <package id="System.Reactive.Linq" version="3.1.1" targetFramework="net451" />
  <package id="System.Reactive.PlatformServices" version="3.1.1" targetFramework="net451" />
</packages>
'@
$pkgNspText = @'
<?xml version="1.0"?>
<package >
  <metadata>
    <id>ProjLib</id>
    <version>1.0.2</version>
    <authors>joglethorpe</authors>
    <owners>Jamie Oglethorpe</owners>
    <projectUrl>https://somewhere.com</projectUrl>
    <requireLicenseAcceptance>false</requireLicenseAcceptance>
    <description>ProjLib</description>
    <releaseNotes>Initial release</releaseNotes>
    <copyright>Copyright 2017</copyright>
    <tags>ProjLib</tags>
  </metadata>
</package>
'@
Describe "Import-NugetSettingsFramework" {
	Context "Exists" {
		It "Is in the module" {
			Get-Command -Module NuGetProjectPacker | where { $_.Name -eq 'Import-NugetSettingsFramework' } | % {
				$_.Name
			} | 
			should be 'Import-NugetSettingsFramework'
		}
	}
	Context "Import from project" {
		$projFolder = "TestDrive:\proj"
		$projPath = "$projFolder\proj.csproj"
		$pkgCfgPath = "$projFolder\packages.config"
		$pkgNspPath = "$projFolder\Package.Nuspec"
		mkdir $projFolder
		$projText | Set-Content $projPath
		$pkgCfgText | Set-Content $pkgCfgPath
		$pkgNspText | Set-Content $pkgNspPath
		$nugetSettings = Import-NugetSettingsFramework -NuspecPath $pkgNspPath -PackagesConfigPath $pkgCfgPath
		$nugetSettings
	}
}