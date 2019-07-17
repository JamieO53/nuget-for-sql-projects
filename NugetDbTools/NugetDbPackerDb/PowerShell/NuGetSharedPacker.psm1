if (-not (Get-Module NugetShared -All)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1"
}
if (-not (Get-Module GitExtension -All)) {
	Import-Module "$PSScriptRoot\GitExtension.psd1"
}
if (-not (Get-Module VSTSExtension -All)) {
	Import-Module "$PSScriptRoot\VSTSExtension.psd1"
}


function Compress-Package {
	<#.Synopsis
	Pack the NuGet package
	.DESCRIPTION
	Uses the NuGet command to create the nuget package from the data at the specified location
	.EXAMPLE
	Compress-Package -NugetPath .\Nuget
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

function Export-NuGetSettings {
	<#.Synopsis
	Initializes the project's NuGet configuration file
	.DESCRIPTION
	Exports the settings to the project's NuGet configuration file
	.EXAMPLE
	Export-NuGetSettings -NugetConfigPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.nuget.config -Settings $settings
	#>
    [CmdletBinding()]
    param
    (
        # The location of .nuget.config file of the project being packaged
        [string]$NugetConfigPath,
		# The values to be set in the NuGet spec
		[PSObject]$Settings
	)
	$options = $Settings.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
	$optionItems = ''
	$options | % {
		$field = $_
		$value = (iex "`$Settings.nugetOptions.$field")
		$optionItems += @"

		<add key=`"$field`" value=`"$value`"/>
"@
	}
	$configText = @"
<?xml version=`"1.0`"?>
<configuration>
	<nugetOptions>
$optionItems
	</nugetOptions>
</configuration>
"@
	[xml]$xml = $configText
	$parentNode = $xml.configuration

	if ($Settings.nugetSettings.Keys.Count -gt 0) {
		$settingsNode = Add-Node -parentNode $parentNode -id nugetSettings
		$Settings.nugetSettings.Keys | % {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
			Add-DictionaryNode -parentNode $settingsNode -key $settingKey -value $settingValue
		}
	}

	if ($Settings.nugetDependencies.Keys.Count -gt 0) {
		$dependenciesNode = Add-Node -parentNode $parentNode -id nugetDependencies
		$Settings.nugetDependencies.Keys | % {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
			Add-DictionaryNode -parentNode $dependenciesNode -key $dependencyKey -value $dependencyValue
		}
	}
	Out-FormattedXml -Xml $xml -FilePath $NugetConfigPath
}

function Get-NuGetPackage {
	<#.Synopsis
	Get the package and its dependency content
	.DESCRIPTION
    Gets the content of all the package and its dependencies
	.EXAMPLE
	Get-NuGetPackage -Id Batch.Batching -Version 0.2.11 -Source 'http://srv103octo01:808/NugetServer/nuget' -OutputDirectory C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The package being retrieved
		[string]$Id,
		# The package version
		[string]$Version,
		# The NuGet server
		[string]$Source,
		# The target for the package content
		[string]$OutputDirectory,
		# The optional Framework version
		[string]$Framework = ''
	)

	$cacheFolder = "$env:userprofile\.nuget\packages\$Id\$Version"
	if (Test-Path $cacheFolder) {
		$targetFolder = "$OutputDirectory\$Id"
		if (-not (Test-Path $targetFolder)) {
			mkdir $targetFolder | Out-Null
		}
		copy $cacheFolder\* $targetFolder -Recurse -Force
	}
}

function Get-NuspecProperty {
	<#.Synopsis
	Get the named property from the project
	.DESCRIPTION
	Get the named property from the nuspec's XML document
	.EXAMPLE
	Get-NuspecProperty -Spec $spec -Property version
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Spec,
		# The property being queried
		[string]$Property
	)
	[string]$prop = iex "`$spec.package.metadata.$Property"
	return $prop.Trim()
}

function Get-PkgProjects {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	return (Get-CSharpProjects -SolutionPath $SolutionPath | ? { $_.Project.EndsWith('Pkg') })
}

function Get-ProjectConfigurationProperty {
	<#.Synopsis
	Get the named property from the project for a specific configuration
	.DESCRIPTION
	Get the named property from the project's XML document for the specified build configuration and platform
	.EXAMPLE
	Get-ProjectProperty -Proj $proj -Property AssemblyName
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Proj,
		# The property being queried
		[string]$Property,
		# The build configuration
		[string]$Configuration,
		# The build platform
		[string]$Platform
	)
	[string]$prop = ''
	$proj.Project.PropertyGroup | % {
		if ($_.Condition) {
			[string]$cond = $_.Condition
			$cond = $cond.Replace('$(Configuration)', $Configuration)
			$cond = $cond.Replace('$(Platform)', $Platform)
			$cond = $cond.Replace('==', '-eq')
			[bool]$isCond = (iex $cond)
		} else {
			[bool]$isCond = -not [string]::IsNullOrWhiteSpace((iex "`$_.$Property"))
		}
		if ($isCond) {
			$prop = iex "`$_.$Property"
			$prop = $prop.Trim()
		}
	}
	return $prop
}


function Get-ProjectProperty {
	<#.Synopsis
	Get the named property from the project
	.DESCRIPTION
	Get the named property from the project's XML document
	.EXAMPLE
	Get-ProjectProperty -Proj $proj -Property AssemblyName
	#>
    [CmdletBinding()]
    param
    (
        # The project's XML document
        [xml]$Proj,
		# The property being queried
		[string]$Property
	)
	[string]$prop = iex "`$proj.Project.PropertyGroup.$Property"
	$prop = $prop.Trim()
	return $prop
}

function Get-ProjectDependencyVersion {
<#.Synopsis
	Get the dependency's version
.DESCRIPTION
	Takes the project's version from the Pkg project if available, otherwise uses the old version
.EXAMPLE
	$ver = Get-ProjectDependencyVersion -Path "$slnFolder\$($slnName)Pkg\$($slnName)Pkg" -Dependency Tools -OldVersion '1.0.418'
#>
    [CmdletBinding()]
    param
    (
        # The solution path
		[string]$SolutionPath,
		# The dependency
		[string]$Dependency,
		#The configuration version used as default
		[string]$OldVersion

	)
	$version = $OldVersion
	$slnFolder = Split-Path $SolutionPath
	Get-PkgProjects -SolutionPath $SolutionPath | % {
		$projPath = [IO.Path]::Combine($slnFolder, $_.ProjectPath)
		[xml]$proj = gc $projPath
		$refs = $proj.Project.ItemGroup | ? { $_.PackageReference }
		$refs.PackageReference | ? { $_.Include -eq $Dependency } | % {
			$version = $_.Version
		}
	}
		
	return $version
}


function Get-ProjectVersion {
<#.Synopsis
	Get the project's version
.DESCRIPTION
	Calculates the project's version from the git repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
.EXAMPLE
	$ver = Get-ProjectVersion -Path . -MajorVersion 1 -MinorVersion 0
#>
    [CmdletBinding()]
    param
    (
        # The project folder
		[string]$Path,
		# Build major version
		[string]$MajorVersion = '0',
		#build minor version
		[string]$MinorVersion = '0',
		# Increase the version by 1
		[bool]$UpVersion = $false
	)
	$majorVer = if ([string]::IsNullOrEmpty($MajorVersion)) { '0'} else { $MajorVersion }
	$minorVer = if ([string]::IsNullOrEmpty($MinorVersion)) { '0'} else { $MinorVersion }
	$latestTag = "$majorVer.$minorVer"
	[int]$revisions = Get-RevisionCount -Path $Path
	if ($UpVersion) {
		$revisions += 1
	}
		
	[string]$version = "$latestTag.$revisions"
		
	$branch = Get-Branch -Path $Path
	if ($branch -and ($branch -ne 'master')) {
		$version += "-$branch"
	}
		
	return $version
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
	$packageFolder = "$SolutionFolder\Packages"
	$contentFolder = Get-NuGetContentFolder
	$solutionContentFolder = "$SolutionFolder\$contentFolder"

	if (Test-Path $packageContentFolder) {
		if (-not $global:testing)
		{
			del $packageContentFolder\* -Recurse -Force
		}
	} else {
		mkdir $packageContentFolder | Out-Null
	}
	
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	rmdir "$SolutionPath\Databases*" -Recurse -Force
	ls $packageContentFolder -Directory | % {
		ls $_.FullName -Directory | ? { (ls $_.FullName -Exclude _._).Count -ne 0 } | % {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			copy "$($_.FullName)\*" "$SolutionFolder\$($_.Name)" -Recurse -Force
		}
	}

	del $packageContentFolder -Include '*' -Recurse -Force

	if ((Test-Path $packageFolder) -and (ls "$packageFolder\**\$contentFolder" -Recurse)) {
		if (Test-Path $solutionContentFolder) {
			rmdir $solutionContentFolder* -Recurse -Force
		}
		mkdir $solutionContentFolder | Out-Null
		ls "$packageFolder\**\$contentFolder" -Recurse | % {
			copy "$($_.FullName)\*" $solutionContentFolder -Recurse -Force
		}
	}
}

function Get-SolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
	$slnFolder = Split-Path -Path $SolutionPath
	nuget restore $SolutionPath | Out-Null

	Get-PkgProjects $SolutionPath | % {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$assetPath = "$projFolder\obj\project.assets.json"

		nuget restore $projPath -Source (Get-NuGetLocalSource) | Out-Null

		$assets = ConvertFrom-Json (gc $assetPath | Out-String)
		$assets.libraries | Get-Member |
			where { $_.MemberType -eq 'NoteProperty' } |
			select -Property Name | 
            where { (Test-Path "$env:UserProfile\.nuget\packages\$($_.Name)") -and
                -not (Test-Path "$env:UserProfile\.nuget\packages\$($_.Name)\lib")} |
			foreach {
				[string]$ref = $_.Name
				$pkgver = $ref.Split('/')
				$package = $pkgver[0]
				$version = $pkgver[1]
				$reference[$package] = $version
			}
	}
	$reference
}

function Get-SolutionPackages {
	<#.Synopsis
	Get the solution's dependency packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
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
	$sln = Split-Path $SolutionPath -Leaf
	$localSource = Get-NuGetLocalSource

	$reference = Get-SolutionDependencies $SolutionPath
	$reference.Keys | sort | % {
		$package = $_
		$version = $reference[$package]
		if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
			Get-NuGetPackage -Id $package -Version $version -Source $localSource -OutputDirectory $ContentFolder
			Set-NuGetDependencyVersion -SolutionPath $slnPath -Dependency $package -Version $version
		}
	}
}

function Import-NuGetSettings
{
	<#.Synopsis
	Import NuGet settings
	.DESCRIPTION
	Import the NuGet spec settings from the project's NuGet configuration file (<projctName>.nuget.config)
	.EXAMPLE
	Import-NuGetSettings -NugetConfigPath 'EcsShared.SharedBase.nuget.config', -SolutionPath $slnPath
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The project's NuGet configuration file
		[Parameter(Mandatory=$true, Position=0)]
		[string]$NugetConfigPath,
		# The solution file
		[string]$SolutionPath
	)
	$nugetSettings = New-NuGetSettings

	if (Test-Path $NugetConfigPath) {
        [xml]$cfg = gc $NugetConfigPath
	    $cfg.configuration.nugetOptions.add | % {
		    if ($_.key -eq 'majorVersion') {
			    $nugetSettings.nugetOptions.majorVersion = $_.value
		    } elseif ($_.key -eq 'minorVersion') {
			    $nugetSettings.nugetOptions.minorVersion = $_.value
		    } elseif ($_.key -eq 'contentFolders') {
			    $nugetSettings.nugetOptions.contentFolders = $_.value
		    }
	    }
	    $cfg.configuration.nugetSettings.add | ? { $_ } | % {
		    $nugetSettings.nugetSettings[$_.key] = $_.value
	    }
	    $projPath = Split-Path -LiteralPath $NugetConfigPath
	    $nugetSettings.nugetSettings['version'] = Get-ProjectVersion -Path $projPath -MajorVersion $nugetSettings.nugetOptions.majorVersion -minorVersion $nugetSettings.nugetOptions.minorVersion
	    $cfg.configuration.nugetDependencies.add | ? { $_ } | % {
		    $version = Get-ProjectDependencyVersion -SolutionPath $SolutionPath -Dependency $_.key -OldVersion $_.value
			$nugetSettings.nugetDependencies[$_.key] = $version
	    }
		$cfg.configuration.nugetContents.add | ? { $_ } | % {
			$nugetSettings.nugetContents[$_.key] = $_.value
		}
    }
	$nugetSettings
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
    #mkdir "$Path\tools" | Out-Null
    #mkdir "$Path\lib" | Out-Null
    #mkdir "$Path\content" | Out-Null
    #mkdir "$Path\content\Databases" | Out-Null
    #mkdir "$Path\build" | Out-Null
}

function Initialize-NuGetRuntime {
	<#.Synopsis
	Initialize the NuGet Runtime folder
	.DESCRIPTION
	Tests if a Runtime folder exists in the project folder or the solution folder.
	If they do then the contents are copied to the Nuget contents\Runtime folder.
	.EXAMPLE
	Initialize-DbPackage -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being packaged
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath,
		# The location of the NuGet folders
		[string]$Path
	)
	$paths = @()
	$solutionFolder = Split-Path $SolutionPath
	$projectFolder = Split-Path $ProjectPath
	$contentFolder = Get-NuGetContentFolder
	$nugetContentFolder = "$Path\content\$contentFolder"
	if ((Test-Path $solutionFolder\$contentFolder) -or (Test-Path $projectFolder\$contentFolder)) {
		if (-not (Test-Path $nugetContentFolder)) {
			mkdir $nugetContentFolder
		}
		if (Test-Path $projectFolder\$contentFolder) {
			copy $projectFolder\$contentFolder\* $nugetContentFolder -Recurse -Force
		}
	}
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

	if (-not (Test-Path $nuGetSpecPath)) {
		$id = $setting.nugetSettings['id']
		pushd $Path
		nuget spec $id
		Rename-Item "$Path\$id.nuspec" 'Package.nuspec'
		popd
	}
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
	$depsNode = Add-Node -parentNode $metadata -id dependencies
	$setting.nugetDependencies.Keys | % {
		$dep = $_
		$ver = $setting.nugetDependencies[$dep]
		$depNode = Add-Node -parentNode $depsNode -id dependency
		$depNode.SetAttribute('id', $dep)
		$depNode.SetAttribute('version', $ver)
	}
	$contFilesNode = Add-Node -parentNode $metadata -id contentFiles
	$setting.nugetContents.Keys | % {
		$files = $_
		$attrs = $setting.nugetContents[$files]
		[xml]$node = "<files include=`"$files`" $attrs/>"
		$childNode = $contFilesNode.AppendChild($contFilesNode.OwnerDocument.ImportNode($node.FirstChild, $true))
	}
	Out-FormattedXml -Xml $specDoc -FilePath $nuGetSpecPath
}

function Initialize-Package
{
	<#.Synopsis
	Initialize the NuGet files for a Visual Studio project
	.DESCRIPTION
	Creates the folders and configuration files for a Visual Studio project Nuget package
		Creates a folder called NuGet in the folder containing the project file.
		The folder is first deleted if it already exists.
	.EXAMPLE
	Initialize-Package -ProjectPath C:\VSTS\Ethel\Ethel\Ethel.csproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .*proj file of the project being packaged
        [string]$ProjectPath,
		# The settings for the NuGet package
		[PSObject]$NugetSettings,
		# The solution file
		[string]$SolutionPath
	)
	$projectFolder = Split-Path -LiteralPath $ProjectPath -Resolve
	$nugetPath = Join-Path -Path $projectFolder -ChildPath 'Nuget'
	Initialize-NuGetFolders -Path $nugetPath
	Initialize-NuGetRuntime -ProjectPath $ProjectPath -SolutionPath $SolutionPath -Path $nugetPath
	Initialize-NuGetSpec -Path $nugetPath -setting $NugetSettings
}

function Measure-ProjectVersion {
<#.Synopsis
	Calculates the project's version from the local repository.
.DESCRIPTION
	Calculates the project's version from the local repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
.EXAMPLE
	$ver = Set-NuspecVersion -Path .\Package.nuspec
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The folder for version calculations
		[string]$ProjectFolder,
		# The previous version to be updated with the new revision number
		[string]$OldVersion,
		# Increase the version by 1
		[bool]$UpVersion = $false
	)
	if (-not $oldVersion) {
		if (Test-Path $Path) {
			[xml]$cfg = gc $Path
			$OldVersion = $cfg.package.metadata.version
			if (-not $oldVersion) {
				$oldVersion = '1.0.0'
			}
		} else {
			$oldVersion = '1.0.0'
		}
	}
	[string[]]$versionParts = $oldVersion.Split('.',3)
	[string]$majorVersion = $versionParts[0]
	[string]$minorVersion = $versionParts[1]
	$minorVersion = $minorVersion.Split('-',2)[0]
	Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion -UpVersion $UpVersion
}

function New-NuGetSettings {
	New-Object -TypeName PSObject -Property @{
		nugetOptions = New-Object -TypeName PSObject -Property @{
				majorVersion = '';
				minorVersion = '';
				contentFolders = '';
			};
		nugetSettings = @{};
		nugetDependencies = @{}
		nugetContents = @{}
	}
}

function Publish-Package {
	<#.Synopsis
	Publish a NuGet package for the project to the local NuGet server
	.DESCRIPTION
    Tests if the latest version of the project has been published.
    
    If not, a new package is created and is pushed to the NuGet server
	.EXAMPLE
	Publish-Package -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sqlproj file of the project being published
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath
	)
    $configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
    $projFolder = Split-Path $ProjectPath -Resolve
    $nugetFolder = [IO.Path]::Combine($projFolder, 'NuGet')
    $settings = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $SolutionPath
    $id = $settings.nugetSettings.Id
    $version = $settings.nugetSettings.version
    if (-not (Test-NuGetVersionExists -Id $id -Version $version)) {
        $nugetPackage = [IO.Path]::Combine($nugetFolder, "$id.$version.nupkg")
        Initialize-Package -ProjectPath $ProjectPath -NugetSettings $settings -SolutionPath $SolutionPath
        Publish-NuGetPackage -PackagePath $nugetPackage
		Remove-NugetFolder $nugetFolder
    }
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
			Set-NuGetProjectDependencyVersion -NugetConfigPath $cfgPath -SolutionPath $SolutionPath -Dependency $Dependency -Version $Version
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
		# The solution file
		[string]$SolutionPath,
		# The dependency being updated
		[string]$Dependency,
		# The new package version
		[string]$Version
	)

	$cfg = Import-NuGetSettings -NugetConfigPath $NugetConfigPath -SolutionPath $SolutionPath
	if (($cfg.nugetDependencies[$Dependency])) {
		$cfg.nugetDependencies[$Dependency] = $Version
 		Export-NuGetSettings -NugetConfigPath $NugetConfigPath -Settings $cfg
	}
}

function Set-NuspecDependencyVersion {
<#.Synopsis
	Set the dependency's version in the Project.nuspec file to the latest version on the server.
.DESCRIPTION
	Fetches the dependency's latest version number and sets it in the .nuspec file.
.EXAMPLE
	Set-NuspecDependencyVersion -Path .\Package.nuspec -Dependency NugetDbPacker
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The dependency name
		[string]$Dependency
	)

	[xml]$spec = gc $Path
	$dependencies = $spec.package.metadata.dependencies
	[xml.XmlElement]$dependencies = Get-GroupNode -ParentNode $spec.package.metadata -Id 'dependencies'
	$newVersion = Get-NuGetPackageVersion $Dependency
	$dep = $dependencies.dependency | ? { $_.id -eq $Dependency }
	if ($dep) {
		$dep.SetAttribute('version', $newVersion)
	} else {
		$newDep = Add-Node -parentNode $dependencies -id 'dependency'
		$newDep.SetAttribute('id', $Dependency)
		$newDep.SetAttribute('version', $newVersion)
	}
	Out-FormattedXml -Xml $spec -FilePath $Path
}

function Set-NuspecVersion {
<#.Synopsis
	Set the project's version in the Project.nuspec file
.DESCRIPTION
	Calculates the project's version from the local repository.
	It uses the most recent tag for the major-minor version number (default 0.0) and counts the number of commits for the release number.
	The updated version number is set in the .nuspec file, and the version is returned.
.EXAMPLE
	$ver = Set-NuspecVersion -Path .\Package.nuspec
#>
    [CmdletBinding()]
    param
    (
        # The path of the .nuspec file
		[string]$Path,
		# The folder for version calculations
		[string]$ProjectFolder,
		# Increase the version by 1
		[bool]$UpVersion = $false
	)

	[xml]$cfg = gc $Path
	$oldVersion = $cfg.package.metadata.version
	$newVersion = Measure-ProjectVersion -Path $Path -ProjectFolder $ProjectFolder -OldVersion $oldVersion -UpVersion $UpVersion
	Set-NodeText -parentNode $cfg.package.metadata -id version -text $newVersion
	Out-FormattedXml -Xml $cfg -FilePath $Path
	$newVersion
}

function Step-Version {
<#.Synopsis
	Increases the release count of the version
.DESCRIPTION
	Increases the third part of the version.
.EXAMPLE
	$ver = Step-Version -Version 1.0.123
	# $ver -eq 1.0.124
.EXAMPLE
	$ver = Step-Version -Version 1.0.123-Branch
	# $ver -eq 1.0.124-Branch
#>
    [CmdletBinding()]
    param
    (
		#Version being increased
		[string]$Version
	)

	$parts = $Version.Split('.',3)
	$major = $parts[0]
	$minor = $parts[1]
	$revisions = $parts[2]

	$revParts = $revisions.Split('-',2)

	[int]$newRev = $revParts[0]
	$newRev += 1
	$branch = ''
	if ($revParts.Count -eq 2) {
		$branch = "-$($revParts[1])"
	}
	return "$major.$minor.$newRev$($branch)"
}


