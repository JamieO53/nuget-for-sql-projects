if (-not (Get-Module NugetShared -All)) {
	Import-Module "$PSScriptRoot\NugetShared.psd1" -Global
}
#if (-not (Get-Module GitExtension -All)) {
#	Import-Module "$PSScriptRoot\GitExtension.psd1"
#}
#if (-not (Get-Module VSTSExtension -All)) {
#	Import-Module "$PSScriptRoot\VSTSExtension.psd1"
#}
Import-Extensions

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
        # The NuGet package specification path
		[string]$NuspecPath,
		# The location of the NuGet data
        [string]$NugetFolder,
		# The folder where the package is created
		[string]$PackageFolder 
	)
	NuGet pack $NuspecPath -BasePath $NugetFolder -OutputDirectory $PackageFolder
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
	$options = $Settings.nugetOptions | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object { $_.Name }
	$optionItems = ''
	$options | ForEach-Object {
		$field = $_
		$value = (Invoke-Expression "`$Settings.nugetOptions.$field")
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
		$Settings.nugetSettings.Keys | ForEach-Object {
			$settingKey = $_
			$settingValue = $Settings.nugetSettings[$_]
			Add-DictionaryNode -parentNode $settingsNode -key $settingKey -value $settingValue
		}
	}

	if ($Settings.nugetDependencies.Keys.Count -gt 0) {
		$dependenciesNode = Add-Node -parentNode $parentNode -id nugetDependencies
		$Settings.nugetDependencies.Keys | ForEach-Object {
			$dependencyKey = $_
			$dependencyValue = $Settings.nugetDependencies[$_]
			Add-DictionaryNode -parentNode $dependenciesNode -key $dependencyKey -value $dependencyValue
		}
	}
	Out-FormattedXml -Xml $xml -FilePath $NugetConfigPath
}

function Get-AllSolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-AllSolutionDependencies -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
	$slnFolder = Split-Path -Path $SolutionPath
	# nuget restore $SolutionPath | Out-Null

	Get-PkgProjects $SolutionPath | ForEach-Object {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$assetPath = "$projFolder\obj\project.assets.json"

		nuget restore $projPath -Source (Get-NuGetLocalSource) | Out-Null

		$assets = ConvertFrom-Json (Get-Content $assetPath | Out-String)
		$dep = Get-AssetDependencies($assets)
		$lib = Get-AssetLibraries($assets)
		$tgt = Get-AssetTargets($assets)

		$deps = $dep
		while ($deps.Count -gt 0) {
			$refs = $deps
			$deps = @{}
			$refs.Keys | ForEach-Object {
				if (-not $reference[$_]) {
					$reference[$_] = $lib[$_]
					if ($tgt[$_]) {
						$tgt[$_] | Where-Object { -not $reference[$_] } | ForEach-Object {
							$deps[$_] = $lib[$_]
						}
					}
				}
			}
		}
	}
	$reference
}

function Get-AssetDependencies($assets) {
    $dependencies = $assets.project.frameworks.'netstandard1.4'.dependencies
    $dep = @{}
    $dependencies | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | Where-Object {
        $id = $_.Name
        $info = Invoke-Expression "`$dependencies.'$id'"
        -not $info.autoReferenced
    } | ForEach-Object {
        $id = $_.Name
        $info = Invoke-Expression "`$dependencies.'$id'"
        $dep[$id] = $info.version
    }
    $dep
}

function Get-AssetLibraries($assets) {
    $libraries = $assets.libraries
    $lib = @{}
    $libraries | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
        $idVer = $_.Name.Split('/')
        $lib[$idVer[0]] = $idVer[1]
    }
    $lib    
}

function Get-AssetTargets($assets) {
    $targets = $assets.targets.'.NETStandard,Version=v1.4'
    $tgt = @{}
    $targets | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
        $idVer = $_.Name
        $id = $idVer.Split('/')[0]
        $info = Invoke-Expression "`$targets.'$idVer'"
        if ($info.dependencies) {
            $targetDependencies = $info.dependencies | Where-Object { $_ } | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
                $_.Name
            }
            $tgt[$id] = $targetDependencies
        } else {
            $tgt[$id] = $null
        }
    }
    $tgt
}

function Get-NuGetPackage {
	<#.Synopsis
	Get the package and its dependency content
	.DESCRIPTION
    Gets the content of all the package and its dependencies
	.EXAMPLE
	Get-NuGetPackage -Id Batch.Batching -Version 0.2.11 -Source 'https://nuget.pkg.github.com/JamieO53/index.json' -OutputDirectory C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The package being retrieved
		[string]$Id,
		# The package version
		[string]$Version,
		# The NuGet servers
		[string]$Sources,
		# The target for the package content
		[string]$OutputDirectory,
		# The optional Framework version
		[string]$Framework = ''
	)

	$cacheFolder = "$env:userprofile\.nuget\packages\$id\$version"
	mkdir $OutputDirectory\$id | Out-Null
	Copy-Item $cacheFolder\* $OutputDirectory\$id -Recurse -Force
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
	[string]$prop = Invoke-Expression "`$spec.package.metadata.$Property"
	return $prop.Trim()
}


function Get-PackageTools {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-PackageTools -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"

    Log "Get tool packages: $SolutionPath"
	Get-PackageToolsPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	Get-ChildItem $packageContentFolder -Directory | ForEach-Object {
		Get-ChildItem $_.FullName -Directory | Where-Object { (Get-ChildItem $_.FullName -Exclude _._).Count -ne 0 } | ForEach-Object {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			Copy-Item "$($_.FullName)\*" "$solutionFolder\$($_.Name)\" -Recurse -Force
		}
	}

	Remove-Item $packageContentFolder* -Recurse -Force
}

function Get-PackageToolsPackages {
	<#.Synopsis
	Get the package tools packages
	.DESCRIPTION
    Gets the content of all the solution's NuGet package tools dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
	.EXAMPLE
	Get-PackageToolsPackages -SolutionPath C:\VSTS\Batch\Batch.sln -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)

	Log "Get package tools dependencies"
    $reference = Get-PackageToolDependencies $SolutionPath
	Get-ReferencedPackages -SolutionPath $SolutionPath -Reference $reference -ContentFolder $ContentFolder
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
	return (Get-CSharpProjects -SolutionPath $SolutionPath | Where-Object { $_.Project.EndsWith('Pkg') })
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
	$proj.Project.PropertyGroup | ForEach-Object {
		if ($_.Condition) {
			[string]$cond = $_.Condition
			$cond = $cond.Replace('$(Configuration)', $Configuration)
			$cond = $cond.Replace('$(Platform)', $Platform)
			$cond = $cond.Replace('==', '-eq')
			[bool]$isCond = (Invoke-Expression $cond)
		} else {
			[bool]$isCond = -not [string]::IsNullOrWhiteSpace((Invoke-Expression "`$_.$Property"))
		}
		if ($isCond) {
			$prop = Invoke-Expression "`$_.$Property"
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
	[string]$prop = Invoke-Expression "`$proj.Project.PropertyGroup.$Property"
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
	Get-PkgProjects -SolutionPath $SolutionPath | ForEach-Object {
		$projPath = [IO.Path]::Combine($slnFolder, $_.ProjectPath)
		[xml]$proj = Get-Content $projPath
		$refs = $proj.Project.ItemGroup | Where-Object { $_.PackageReference }
		$refs.PackageReference | Where-Object { $_.Include -eq $Dependency } | ForEach-Object {
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


function Get-ReferencedPackages {
	<#.Synopsis
	Get the referenced packages
	.DESCRIPTION
    Gets the content of all the referenced dependencies and updates the SQL projects' NuGet versions for each dependency
	The project nuget configurations are updated with the new versions.
	.EXAMPLE
	Get-ReferencedPackages -SolutionPath C:\VSTS\Batch\Batch.sln -References $reference -ContentFolder C:\VSTS\Batch\PackageContent
	#>
    [CmdletBinding()]
    param
    (
		# The location of .sln file of the solution being updated
		[string]$SolutionPath,
		# The packages being installed
        [hashtable]$reference,
		# The folder where the package content is to be installed
		[string]$ContentFolder
	)

	if (Test-Path $packageContentFolder) {
		Remove-Item $packageContentFolder* -Recurse -Force
	}
	mkdir $packageContentFolder | Out-Null

	$localSources = [string]::Join("' -Source '",(Get-NuGetCachePaths))
	$reference.Keys | Sort-Object | ForEach-Object {
		$package = $_
		$version = $reference[$package]
		if (-not $global:testing -or (Test-NuGetVersionExists -Id $package -Version $version)) {
			Log "Getting $package $version"
			Get-NuGetPackage -Id $package -Version $version -Sources $localSources -OutputDirectory $ContentFolder
			Set-NuGetDependencyVersion -SolutionPath $SolutionPath -Dependency $package -Version $version
		}
	}
}

function Get-SolutionContent {
	<#.Synopsis
	Get the solution's dependency content
	.DESCRIPTION
    Gets the content of all the solution's NuGet dependencies and updates the SQL projects' NuGet versions for each dependency
	.EXAMPLE
	Get-SolutionContent -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$solutionFolder = Split-Path $SolutionPath
	$packageContentFolder = "$SolutionFolder\PackageContent"
	$packageFolder = "$SolutionFolder\packages"
	$contentFolder = Get-NuGetContentFolder
	$solutionContentFolder = "$SolutionFolder\$contentFolder"

	if (-not $contentFolder) {
		$configFolder = (Get-Item (Get-NuGetDbToolsConfigPath)).FullName
		Log "Content folder not specified in $configFolder" -Error
		exit 1
	}

	Log "Get solution packages: $SolutionPath"
	Get-SolutionPackages -SolutionPath $SolutionPath -ContentFolder $packageContentFolder

	Remove-Item "$SolutionPath\Databases*" -Recurse -Force
	Get-ChildItem $packageContentFolder -Directory | ForEach-Object {
		Get-ChildItem $_.FullName -Directory | Where-Object { (Get-ChildItem $_.FullName -Exclude _._).Count -ne 0 } | ForEach-Object {
			if (-not (Test-Path "$SolutionFolder\$($_.Name)")) {
				mkdir "$SolutionFolder\$($_.Name)" | Out-Null
			}
			Copy-Item "$($_.FullName)\*" "$SolutionFolder\$($_.Name)\" -Recurse -Force
		}
	}

	Remove-Item $packageContentFolder* -Recurse -Force

	$csPackage = @{}
	Get-ChildItem .\**\packages.config | ForEach-Object {
		[xml]$pc = Get-Content $_
		$pc.packages.package | ForEach-Object {
			New-Object -TypeName PSCustomObject -Property @{ id=$_.id; version=$_.version }
		}
	} | Sort-Object -Property id,version -Unique | ForEach-Object {
		$csPackage[$_.id] = $_.version
	}
	
	if ((Test-Path $packageFolder) -and (Get-ChildItem "$packageFolder\**\$contentFolder" -Recurse)) {
		if (Test-Path $solutionContentFolder) {
			Remove-Item $solutionContentFolder\* -Recurse -Force
		} else {
			mkdir $solutionContentFolder | Out-Null
		}
		$csPackage.Keys | Sort-Object | ForEach-Object {
			$id = $_
			$version = $csPackage[$id]
			$idContentFolder = "$packageFolder\$id.$version\content\$contentFolder"
			if (Test-Path $idContentFolder) {
				Copy-Item "$idContentFolder\*" "$solutionContentFolder\" -Recurse -Force
			}
		}
	}
}

function Get-SolutionDependencies {
	<#.Synopsis
	Get the solution's dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's NuGet dependencies
	.EXAMPLE
	Get-SolutionDependencies -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
	$reference = @{}
    $all = Get-AllSolutionDependencies -SolutionPath $SolutionPath
    $all.Keys | Where-Object { $_ -notlike 'Nuget*'} |
        ForEach-Object {
            $reference[$_] = $all[$_]
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

	Log "Get solution dependencies"
	$reference = Get-SolutionDependencies $SolutionPath
	Get-ReferencedPackages -SolutionPath $SolutionPath -Reference $reference -ContentFolder $ContentFolder
}

function Get-PackageToolDependencies {
	<#.Synopsis
	Get the solution's  package tool dependencies
	.DESCRIPTION
    Gets the name and version of all the solution's package tool NuGet dependencies
	.EXAMPLE
	Get-PackageToolDependencies -SolutionPath C:\VSTS\Batch\Batch.sln
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath
	)
    $reference = @{}
    $all = Get-AllSolutionDependencies -SolutionPath $SolutionPath
    $all.Keys | Where-Object { $_ -like 'Nuget*'} |
        ForEach-Object {
            $reference[$_] = $all[$_]
        }
    $reference
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
        [xml]$cfg = Get-Content $NugetConfigPath
	    $cfg.configuration.nugetOptions.add | ForEach-Object {
		    if ($_.key -eq 'majorVersion') {
			    $nugetSettings.nugetOptions.majorVersion = $_.value
		    } elseif ($_.key -eq 'minorVersion') {
			    $nugetSettings.nugetOptions.minorVersion = $_.value
		    } elseif ($_.key -eq 'contentFolders') {
			    $nugetSettings.nugetOptions.contentFolders = $_.value
		    }
	    }
	    $cfg.configuration.nugetSettings.add | Where-Object { $_ } | ForEach-Object {
		    $nugetSettings.nugetSettings[$_.key] = $_.value
	    }
	    $projPath = Split-Path -LiteralPath $NugetConfigPath
	    $nugetSettings.nugetSettings['version'] = Get-ProjectVersion -Path $projPath -MajorVersion $nugetSettings.nugetOptions.majorVersion -minorVersion $nugetSettings.nugetOptions.minorVersion
	    $cfg.configuration.nugetDependencies.add | Where-Object { $_ } | ForEach-Object {
		    $version = Get-ProjectDependencyVersion -SolutionPath $SolutionPath -Dependency $_.key -OldVersion $_.value
			$nugetSettings.nugetDependencies[$_.key] = $version
	    }
		$cfg.configuration.nugetContents.add | Where-Object { $_ } | ForEach-Object {
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
	$projectFolder = Split-Path $ProjectPath
	$contentFolder = Get-NuGetContentFolder
	$nugetContentFolder = "$Path\content\$contentFolder"
	if ($contentFolder -and (Test-Path $projectFolder\$contentFolder)) {
		if (-not (Test-Path $nugetContentFolder)) {
			mkdir $nugetContentFolder
		}
		if (Test-Path $projectFolder\$contentFolder) {
			Log "Copying $projectFolder\$contentFolder\* to $nugetContentFolder"
			Copy-Item $projectFolder\$contentFolder\* $nugetContentFolder -Recurse -Force
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
		Push-Location $Path
		nuget spec $id
		Rename-Item "$Path\$id.nuspec" 'Package.nuspec'
		Pop-Location
	}
	[xml]$specDoc = Get-Content $nuGetSpecPath
    $metadata = $specDoc.package.metadata

	$nodes = @()
	$metadata.ChildNodes | Where-Object { -not $setting.nugetSettings.Contains($_.Name) } | ForEach-Object { $nodes += $_.Name }
	$nodes | ForEach-Object {
		$name = $_
		Remove-Node -parentNode $metadata -id $name
	}
	if ($metadata.dependencies) {
		Remove-Node -parentnode $metadata -id 'dependencies'
	}
	$setting.nugetSettings.Keys | ForEach-Object {
		$name = $_
		$value = $setting.nugetSettings[$name]
		Set-NodeText -parentNode $metadata -id $name -text $value
	}
	$depsNode = Add-Node -parentNode $metadata -id dependencies
	$setting.nugetDependencies.Keys | ForEach-Object {
		$dep = $_
		$ver = $setting.nugetDependencies[$dep]
		$depNode = Add-Node -parentNode $depsNode -id dependency
		$depNode.SetAttribute('id', $dep)
		$depNode.SetAttribute('version', $ver)
	}
	$contFilesNode = Add-Node -parentNode $metadata -id contentFiles
	$setting.nugetContents.Keys | ForEach-Object {
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
			[xml]$cfg = Get-Content $Path
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
    Get-SqlProjects -SolutionPath $SolutionPath | ForEach-Object {
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
		[string]$Dependency,
		# The optional Branch - Prerelease label
		[string]$Branch = $null
	)

	[xml]$spec = Get-Content $Path
	$dependencies = $spec.package.metadata.dependencies
	[xml.XmlElement]$dependencies = Get-GroupNode -ParentNode $spec.package.metadata -Id 'dependencies'
	$newVersion = Get-NuGetPackageVersion -PackageName $Dependency -Branch $Branch
	$dep = $dependencies.dependency | Where-Object { $_.id -eq $Dependency }
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

	[xml]$cfg = Get-Content $Path
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


