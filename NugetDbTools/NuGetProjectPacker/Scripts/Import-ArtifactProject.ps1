function Import-ArtifactProject {
	<#.Synopsis
	Copy the build files to the Artifact lib folder
	.DESCRIPTION
	Copies the binary debug and config files to the Artifact lib folder
	.EXAMPLE
	Import-ArtifactProject -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.csproj
		-ProjBinFolder C:\VSTS\EcsShared\SupportRoles\bin\net451
		-ArtifactBinFolder C:\VSTS\EcsShared\SupportRoles\NuGet\lib
	#>
    [CmdletBinding()]
    param
    (
        # The location of .csproj file of the project being packaged
        [string]$ProjectPath,
		# The location of the project bin folder
		[string]$ProjBinFolder,
		# The location of the NuGet bin folder
		[string]$ArtifactBinFolder,
		# The name of the project
		[string]$DefaultAssemblyName
	)

	[xml]$proj = Get-Content $ProjectPath
	[string]$framework = (Get-ProjectProperty -Proj $proj -Property TargetFrameworkVersion)
	
	if (-not $framework){
		#try netStandard if empty
		$framework = (Get-ProjectProperty -Proj $proj -Property TargetFramework)
	}
	
	$binFramework = $framework.Replace('v','net').Replace('.','')
	
	[string]$assembly = Get-ProjectProperty -Proj $proj -Property AssemblyName
	if (-not $assembly) {
		$assembly = $DefaultAssemblyName
	}
	
	$binFolder = "$ArtifactBinFolder\$binFramework"
	
	if (-not (Test-Path $binFolder)) {
		mkdir $binFolder | Out-Null
	}

	if (-not (Test-Path $ProjBinFolder)) {
		$projectFolder = Split-Path -Path $ProjectPath
		# Debug|AnyCPU hardcoded for now
		[string]$subDir = (Get-ProjectConfigurationProperty -Proj $proj -Property OutputPath -Configuration Debug -Platform AnyCPU)
		$ProjBinFolder = [IO.Path]::Combine($projectFolder, $subDir)
	}

	Get-ChildItem -Path $ProjBinFolder -Recurse -Filter "$assembly.*" | Copy-Item -Destination $binFolder
}
