function Import-NuGetDb {
	<#.Synopsis
	Copy the build files to the NuGet content folder
	.DESCRIPTION
	Copies the dacpac and CLR assembly files to the NuGet content folder
	.EXAMPLE
	Import-NuGetDb -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
		-ProjDbFolder C:\VSTS\EcsShared\SupportRoles\Databases
		-NugetDbFolder C:\VSTS\EcsShared\SupportRoles\NuGet\content\Databases
		-NugetSpecPath C:\VSTS\EcsShared\SupportRoles\NuGet\Project.nuspec
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath,
		# The location of the project Databases folder
		[string]$ProjDbFolder,
		# The location of the NuGet Databases folder
		[string]$NugetDbFolder,
		# The location of the NuGet spec file
		[string]$NugetSpecPath
	)
	[xml]$proj = Get-Content $ProjectPath
	[string]$dacpac = Get-ProjectProperty -Proj $proj -Property DacApplicationName
	if ($dacpac -eq '') {
		$dacpac = ([string]($proj.Project.PropertyGroup.Name | ? { $_ -ne 'PropertyGroup'})).Trim()
	}
	[string]$assembly = Get-ProjectProperty -Proj $proj -Property AssemblyName

	if (Test-Path "$ProjDbFolder\$dacpac.dacpac") {
		Copy-Item "$ProjDbFolder\$dacpac.dacpac" $NugetDbFolder
	}
	Copy-Item "$ProjDbFolder\*.*" $NugetDbFolder
	ls $ProjDbFolder -Directory | % {
		$dir = $_.Name
		md "$NugetDbFolder\$dir"  | Out-Null
		if (Test-Path "$ProjDbFolder\$dir\$dacpac.dacpac") {
			Copy-Item "$ProjDbFolder\$dir\$dacpac.dacpac" "$NugetDbFolder\$dir"
		}
		Copy-Item "$ProjDbFolder\$dir\*.dll" "$NugetDbFolder\$dir"
	}
	[xml]$spec = gc $NugetSpecPath
	Add-DbFileNode -parentNode $spec.package
	Out-FormattedXml -Xml $spec -FilePath $NugetSpecPath
}

