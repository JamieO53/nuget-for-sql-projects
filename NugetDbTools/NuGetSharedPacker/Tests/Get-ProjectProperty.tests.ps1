if ( Get-Module NugetSharedPacker) {
	Remove-Module NugetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetSharedPacker\NugetSharedPacker.psm1"

[xml]$proj = @"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<Project ToolsVersion=`"12.0`" DefaultTargets=`"Build`" xmlns=`"http://schemas.microsoft.com/developer/msbuild/2003`">
  <PropertyGroup>
    <Configuration Condition=`" '`$(Configuration)' == '' `">Debug</Configuration>
    <Platform Condition=`" '`$(Platform)' == '' `">AnyCPU</Platform>
    <ProductVersion>8.0.30703</ProductVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>{A149354A-9827-4FE1-BE45-1DCA6030625F}</ProjectGuid>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>eCentric.Atlas</RootNamespace>
    <AssemblyName>AtlasCore</AssemblyName>
    <TargetFrameworkVersion>v4.5.1</TargetFrameworkVersion>
    <FileAlignment>512</FileAlignment>
    <TargetFrameworkProfile />
  </PropertyGroup>
</Project>
"@
Describe "Get-ProjectProperty" {
	Context "Property Exists" {
		It "OutputType" {
			Get-ProjectProperty -Proj $proj -Property OutputType | should be 'Library'
		}
	}
	Context "Property Doesn't Exist" {
		It "Rubbish" {
			Get-ProjectProperty -Proj $proj -Property Rubbish | should be ''
		}
	}
}