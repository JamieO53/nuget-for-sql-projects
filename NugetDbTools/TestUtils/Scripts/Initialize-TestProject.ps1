function Initialize-TestProject {
	param (
		[string]$ProjectPath
	)
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
	$projText | Set-Content $ProjectPath
}