function Import-NuGetProject {
	<#.Synopsis
	Copy the build files to the NuGet lib folder
	.DESCRIPTION
	Copies the binary debug and config files to the NuGet lib folder
	.EXAMPLE
	Import-NuGetProject -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.csproj
		-ProjBinFolder C:\VSTS\EcsShared\SupportRoles\bin\net451
		-NugetBinFolder C:\VSTS\EcsShared\SupportRoles\NuGet\lib
		-NugetSpecPath C:\VSTS\EcsShared\SupportRoles\NuGet\Project.nuspec
	#>
    [CmdletBinding()]
    param
    (
        # The location of .csproj file of the project being packaged
        [string]$ProjectPath,
		# The location of the project bin folder
		[string]$ProjBinFolder,
		# The location of the NuGet bin folder
		[string]$NugetBinFolder,
		# The location of the NuGet spec file
		[string]$NugetSpecPath
	)
	[xml]$proj = Get-Content $ProjectPath
	[string]$assembly = Get-ProjectProperty -Proj $proj -Property AssemblyName
	[string]$framework = (Get-ProjectProperty -Proj $proj -Property TargetFrameworkVersion).Replace('v','net').Replace('.','')
	$binFolder = "$NugetBinFolder\$framework"
	if (-not (Test-Path $binFolder)) {
		mkdir $binFolder
	}

	Copy-Item "$ProjBinFolder\$assembly.*" $binFolder
}

