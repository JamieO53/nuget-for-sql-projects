if (-not (Get-Module NugetShared)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1"
}

function Add-DbFileNode ($parentNode) {
	$files = @"
<files>
  <file src="content\Databases\**" target="Databases" />
</files>
"@
	[xml]$child = $files
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.FirstChild, $true))
}

function Get-SolutionContent {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"

	if (Test-Path $packageContentFolder) {
		if (-not $global:testing)
		{
			del $packageContentFolder\* -Recurse -Force
		}
	} else {
		mkdir $packageContentFolder | Out-Null
	}
	
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	ls $packageContentFolder -Directory | % {
		ls $_.FullName -Directory | % {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)"
			}
			copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)"
		}
	}

	del $packageContentFolder\ -Include '*' -Recurse
}

function Get-SolutionPackages {
	<#.Synopsis
	Get the solution's dependency packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)
	$slnFolder = Split-Path $SolutionPath
	$localSource = Get-NuGetLocalSource

	Get-CSharpProjects -SolutionPath $SolutionPath | ? { $_.Project.EndsWith('Pkg') } | % {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		[xml]$proj = gc $projPath
		$proj.Project.ItemGroup.PackageReference | % {
			$package = $_.Include
			$version = $_.Version
			if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
				iex "nuget install $package -Version '$version' -Source '$localSource' -OutputDirectory '$ContentFolder' -ExcludeVersion"
			}
			Set-NuGetDependencyVersion -SolutionPath $SolutionPath -Dependency $_.Include -Version $_.Version
		}
	}
}

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
	[string]$dacpac = ([string]$proj.Project.PropertyGroup.DacApplicationName).Trim()
	if ($dacpac -eq '') {
		$dacpac = ([string]($proj.Project.PropertyGroup.Name | ? { $_ -ne 'PropertyGroup'})).Trim()
	}
	[string]$assembly = ([string]$proj.Project.PropertyGroup.AssemblyName).Trim()

	if (Test-Path "$ProjDbFolder\$dacpac.dacpac") {
		Copy-Item "$ProjDbFolder\$dacpac.dacpac" $NugetDbFolder
	}
	Copy-Item "$ProjDbFolder\$assembly.*" $NugetDbFolder
	ls $ProjDbFolder -Directory | % {
		$dir = $_.Name
		md "$NugetDbFolder\$dir"  | Out-Null
		if (Test-Path "$ProjDbFolder\$dir\$dacpac.dacpac") {
			Copy-Item "$ProjDbFolder\$dir\$dacpac.dacpac" "$NugetDbFolder\$dir"
		}
		Copy-Item "$ProjDbFolder\$dir\$assembly.*" "$NugetDbFolder\$dir"
	}
	[xml]$spec = gc $NugetSpecPath
	Add-DbFileNode -parentNode $spec.package
	Out-FormattedXml -Xml $spec -FilePath $NugetSpecPath
}


function Compress-DbPackage
{
	<#.Synopsis
	Pack the database NuGet package
	.DESCRIPTION
	Uses the NuGet command to create the nuget package from the data at the specified location
	.EXAMPLE
	Compress-DbPackage -NugetPath .\Nuget
	#>
    [CmdletBinding()]
    param
    (
        # The location of the NuGet data
        [string]$NugetPath
	)
	Push-Location -LiteralPath $NugetPath
	NuGet pack -BasePath $NugetPath
	Pop-Location
}

function Publish-DbPackage {
	<#.Synopsis
	Publish a NuGet package for the DB project to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of the project has been published.
    
    If not, a new package is created and is pushed to the NuGet server
	.EXAMPLE
	Publish-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being published
        [string]$ProjectPath
	)
    $configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
    $projFolder = Split-Path $ProjectPath -Resolve
    $nugetFolder = [IO.Path]::Combine($projFolder, 'NuGet')
    $settings = Import-NuGetSettings -NugetConfigPath $configPath
    $id = $settings.nugetSettings.Id
    $version = $settings.nugetSettings.version
    if (-not (Test-NuGetVersionExists -Id $id -Version $version)) {
        $nugetPackage = [IO.Path]::Combine($nugetFolder, "$id.$version.nupkg")
        Initialize-DbPackage -ProjectPath $ProjectPath
        $source = Get-NuGetLocalSource
        $apiKey = Get-NuGetLocalApiKey
        nuget push $nugetPackage $apiKey -Source $source
		Remove-NugetFolder $nugetFolder
    }
}

function Publish-SolutionDbPackages {
	<#.Synopsis
	Publish a NuGet package for each DB project in the solution to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of each DB project has been published.
    
    If not, a new package is created for them and are pushed to the NuGet server
	.EXAMPLE
	Publish-SolutionDbPackages -ProjectPath C:\VSTS\EcsShared\EcsShared.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being published
        [string]$SolutionPath
	)
    $solutionFolder = Split-Path -Path $SolutionPath
    Get-SqlProjects -SolutionPath $SolutionPath | % {
        $project = $_.Project
        [string]$projectPath = [IO.Path]::Combine($solutionFolder, $_.ProjectPath)
        Publish-DbPackage -ProjectPath $projectPath
    }
}

function Remove-Node ($parentNode, $id){
	$childNode = $parentNode.SelectSingleNode($id)
	$parentNode.RemoveChild($childNode) | Out-Null
}

function Remove-NugetFolder {
    [CmdletBinding()]
	param (
		# The location of the NuGet folders
		[string]$Path
	)
	if (Test-Path $Path) {
		Remove-Item -Path "$Path\*" -Recurse -Force
		Remove-Item -Path $Path -Recurse
	}
}

function Set-NodeText ($parentNode, $id, [String]$text){
	[xml.XmlNode]$childNode
	$parentNode.SelectSingleNode($id) |
		where { $_ } |
		foreach {
			$childNode = $_
		}
    if (-not $childNode) {
		[xml]$child = "<$id>$text</$id>"
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.FirstChild, $true))
	}
	else
	{
		$childNode.InnerText = $text
	}
}

function Set-NuGetDependencyVersion {
	<#.Synopsis
	Update the solution's SQL projects NuGet dependendency version
	.DESCRIPTION
    Checks each SQL project in the solution if it has a NuGet dependency on the given dependency. If it does, the version is updated to the given value.
	.EXAMPLE
	Set-NuGetDependencyVersion -SolutionPath C:\VSTS\Batch\Batch.sln -Dependency 'BackOfficeStateManager.StateManager' -Version '0.1.2'
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The dependency being updated
		[string]$Dependency,
		# The new package version
		[string]$Version
	)
    $solutionFolder = Split-Path -Path $SolutionPath
    Get-SqlProjects -SolutionPath $SolutionPath | % {
        $project = $_.Project
        [string]$projectPath = [IO.Path]::Combine($solutionFolder, $_.ProjectPath)
		$cfgPath = [IO.Path]::ChangeExtension($projectPath, '.nuget.config')
		if (Test-Path $cfgPath) {
			Set-NuGetProjectDependencyVersion -NugetConfigPath $cfgPath -Dependency $Dependency -Version $Version
		}
    }
}

function Set-NuGetProjectDependencyVersion {
	<#.Synopsis
	Update the SQL project's NuGet dependendency version
	.DESCRIPTION
    Checks if SQL project if it has a NuGet dependency on the given dependency. If it does, the version is updated to the given value.
	.EXAMPLE
	Set-NuGetProjectDependencyVersion -NugetConfigPath C:\VSTS\Batch\Batching\.nuget.config -Dependency 'BackOfficeStateManager.StateManager' -Version '0.1.2'
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .nuget.config file being updated
        [string]$NugetConfigPath,
		# The dependency being updated
		[string]$Dependency,
		# The new package version
		[string]$Version
	)

	$cfg = Import-NuGetSettings -NugetConfigPath $NugetConfigPath
		if ($cfg.nugetDependencies[$Dependency]) {
			$cfg.nugetDependencies[$Dependency] = $Version
		}
 	Export-NuGetSettings -NugetConfigPath $NugetConfigPath -Settings $cfg
}

function Initialize-DbPackage
{
	<#.Synopsis
	Initialize the NuGet files for a SQL Server project
	.DESCRIPTION
	Creates the folders and configuration files for a SQL Server project Nuget package
		Creates a folder called NuGet in the folder containing the project file.
		The folder is first deleted if it already exists.
	.EXAMPLE
	Initialize-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath
	)
	$projectFolder = Split-Path -LiteralPath $ProjectPath -Resolve
	$nugetPath = Join-Path -Path $projectFolder -ChildPath 'Nuget'
	$projectName = Split-Path -Path $projectFolder -Leaf
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	Initialize-NuGetFolders -Path $nugetPath
	$nugetSettings = Import-NuGetSettings -NugetConfigPath $configPath
	Initialize-NuGetSpec -Path $nugetPath -setting $nugetSettings
	Import-NuGetDb -ProjectPath $ProjectPath -ProjDbFolder "$projectFolder\Databases" -NugetDbFolder "$nugetPath\content\Databases" -NugetSpecPath "$nugetPath\Package.nuspec"
	Compress-DbPackage -NugetPath $nugetPath
}

function Initialize-NuGetFolders
{
<#.Synopsis
	Creates the NuGet package folders
.DESCRIPTION
	Create the Nuget root folder and sub-folders
.EXAMPLE
	Initialize-NuGetFolders -Path C:\VSTS\EcsShared\SupportRoles\NuGet
#>
    [CmdletBinding()]
	param (
		# The location of the NuGet folders
		[string]$Path
	)
	Remove-NugetFolder -Path $Path
    mkdir "$Path" | Out-Null
    mkdir "$Path\tools" | Out-Null
    mkdir "$Path\lib" | Out-Null
    mkdir "$Path\content" | Out-Null
    mkdir "$Path\content\Databases" | Out-Null
    mkdir "$Path\build" | Out-Null
}

function Initialize-NuGetSpec {
<#.Synopsis
	Creates the NuGet package specification file
.DESCRIPTION
	Create the Nuget package specification file and initializes its content
.EXAMPLE
	Initialize-NuGetSpec -Path C:\VSTS\EcsShared\SupportRoles\NuGet
#>
    [CmdletBinding()]
	param(
		# The NuGet path
		[string]$Path,
		# The values to be set in the NuGet spec
		[PSObject]$setting
	)
	$nuGetSpecPath = "$Path\Package.nuspec"
	Push-Location -LiteralPath $Path
	nuget spec -force | Out-Null
	Pop-Location

	[xml]$specDoc = Get-Content $nuGetSpecPath
    $metadata = $specDoc.package.metadata
	$nodes = @()
	$metadata.ChildNodes | where { -not $setting.nugetSettings.Contains($_.Name) } | % { $nodes += $_.Name }
	$nodes | % {
		$name = $_
		Remove-Node -parentNode $metadata -id $name
	}
	if ($metadata.dependencies) {
		Remove-Node -parentnode $metadata -id 'dependencies'
	}
	$setting.nugetSettings.Keys | % {
		$name = $_
		$value = $setting.nugetSettings[$name]
		Set-NodeText -parentNode $metadata -id $name -text $value
	}
	[xml]$parent = '<dependencies></dependencies>'
	$depsNode = $parent.FirstChild
	$setting.nugetDependencies.Keys | % {
		$dep = $_
		$ver = $setting.nugetDependencies[$dep]
		[xml]$child = "<dependency id=`"$dep`" version=`"$ver`"/>"
		$childNode = $depsNode.AppendChild($depsNode.OwnerDocument.ImportNode($child.FirstChild, $true))
	}
	$depsNode = $metadata.AppendChild($metadata.OwnerDocument.ImportNode($parent.FirstChild, $true))
    Out-FormattedXml -Xml $specDoc -FilePath $nuGetSpecPath
}

function Initialize-TestNugetConfig {
	param (
		[switch]$NoOptions = $false,
		[switch]$NoSettings = $false,
		[switch]$NoDependencies = $false
	)
	$nugetOptions = New-Object -TypeName PSObject -Property @{
		majorVersion = '1';
		minorVersion = '0'
	}
	$nugetSettings = @{
		id = 'TestPackage';
		version = '1.0.123';
		authors = 'joglethorpe';
		owners = 'Ecentric Payment Systems';
		projectUrl = 'https://epsdev.visualstudio.com/Sandbox';
		description = 'This package is for testing NuGet creation functionality';
		releaseNotes = 'Some stuff to say about the release';
		copyright = 'Copyright 2017'
	}
	$nugetDependencies = @{
		'EcsShared.SharedBase' = '[1.0)';
		'EcsShared.SupportRoles' = '[1.0)'
	}
	$expectedSettings = New-Object -TypeName PSObject -Property @{
		nugetOptions = if ($NoOptions) { $null } else { $nugetOptions };
		nugetSettings = if ($NoSettings) { @{} } else { $nugetSettings };
		nugetDependencies = if ($NoDependencies) { @{} } else { $nugetDependencies }
	}
	return $expectedSettings	
}


