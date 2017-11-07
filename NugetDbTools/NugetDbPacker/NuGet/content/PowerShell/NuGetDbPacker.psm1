if (-not (Get-Module NugetShared)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1"
}

function Add-DbFileNode ($parentNode) {
	$files = @"
<files>
  <file src="content\Databases\*" target="Databases" />
</files>
"@
	[xml]$child = $files
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.FirstChild, $true))
}

function Export-NuGetSettings {
	<#.Synopsis
	Initializes the project's NuGet configuration file
	.DESCRIPTION
	Exports the settings to the project's NuGet configuration file
	.EXAMPLE
	Export-NuGetSettings -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj -Settings $settings
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath,
		# The values to be set in the NuGet spec
		[PSObject]$Settings
	)
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	$major = $Settings.nugetOptions.majorVersion
	$minor = $Settings.nugetOptions.minorVersion
	$configText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetOptions>
		<add key=`"majorVersion`" value=`"$major`"/>
		<add key=`"minorVersion`" value=`"$minor`"/>
	</nugetOptions>
</configuration>
"@
	[xml]$xml = $configText
	$parentNode = $xml.configuration

	if ($Settings.nugetSettings.Keys.Count -gt 0) {
		$Settings.nugetSettings.Keys | select -First 1 | % {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
		}
		$settingText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetSettings>
		<add key=`"$settingKey`" value=`"$settingValue`"/>
	</nugetSettings>
</configuration>
"@
		[xml]$SettingsXml = $settingText
		$settingsNode = $SettingsXml.configuration.nugetSettings
		$Settings.nugetSettings.Keys | select -Skip 1 | % {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
			Add-DictionaryNode -parentNode $settingsNode -key $settingKey -value $settingValue
		}
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($settingsNode, $true))
	}

	if ($Settings.nugetDependencies.Keys.Count -gt 0) {
		$Settings.nugetDependencies.Keys | select -First 1 | % {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
		}
		$dependencyText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetDependencies>
		<add key=`"$dependencyKey`" value=`"$dependencyValue`"/>
	</nugetDependencies>
</configuration>
"@
		[xml]$dependencyXml = $dependencyText
		$dependenciesNode = $dependencyXml.configuration.nugetDependencies
		$Settings.nugetDependencies.Keys | select -Skip 1 | % {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
			Add-DictionaryNode -parentNode $dependenciesNode -key $dependencyKey -value $dependencyValue
		}
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($dependenciesNode, $true))
	}
	Out-FormattedXml -Xml $xml -FilePath $configPath
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
	Copy-Item "$ProjDbFolder\$dacpac.dacpac" $NugetDbFolder
	Copy-Item "$ProjDbFolder\$assembly.*" $NugetDbFolder
	[xml]$spec = gc $NugetSpecPath
	Add-DbFileNode -parentNode $spec.package
	Out-FormattedXml -Xml $spec -FilePath $NugetSpecPath
}


function Import-NuGetSettings
{
	<#.Synopsis
	Import NuGet settings
	.DESCRIPTION
	Import the NuGet spec settings from the project's NuGet configuration file (<projctName>.nuget.config)
	.EXAMPLE
	Import-NuGetSettings -Path 'EcsShared.SharedBase.nuget.config'
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The project's NuGet configuration file
		[Parameter(Mandatory=$true, Position=0)]
		[string]$Path
	)
	$nugetSettings = New-Object -TypeName PSObject -Property @{
		nugetOptions = New-Object -TypeName PSObject -Property @{
				majorVersion = '';
				minorVersion = ''
			};
		nugetSettings = @{};
		nugetDependencies = @{}
	}

	[xml]$cfg = gc $Path
	$cfg.configuration.nugetOptions.add | % {
		if ($_.key -eq 'majorVersion') {
			$nugetSettings.nugetOptions.majorVersion = $_.value
		} elseif ($_.key -eq 'minorVersion') {
			$nugetSettings.nugetOptions.minorVersion = $_.value
		}
	}
	$cfg.configuration.nugetSettings.add | ? { $_ } | % {
		$nugetSettings.nugetSettings[$_.key] = $_.value
	}
	$projPath = Split-Path -LiteralPath $Path
	$nugetSettings.nugetSettings['version'] = Get-ProjectVersion -Path $projPath -MajorVersion $nugetSettings.nugetOptions.majorVersion -minorVersion $nugetSettings.nugetOptions.minorVersion
	$cfg.configuration.nugetDependencies.add | ? { $_ } | % {
		$nugetSettings.nugetDependencies[$_.key] = $_.value
	}
	$nugetSettings
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
    $settings = Import-NuGetSettings -Path $configPath
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
	$nugetSettings = Import-NuGetSettings -Path $configPath
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


