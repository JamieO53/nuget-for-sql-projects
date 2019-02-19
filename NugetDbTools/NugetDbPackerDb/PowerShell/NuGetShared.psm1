
function Add-DictionaryNode ($parentNode, $key, $value) {
	$xml = @"
<nodes>
  <add key="$key" value="$value" />
</nodes>
"@
	[xml]$child = $xml
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.nodes.FirstChild, $true))
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
	Out-FormattedXml -Xml $xml -FilePath $NugetConfigPath
}

Function Format-XmlIndent
{
    # https://gist.github.com/PrateekKumarSingh/96032bd63edb3100c2dda5d64847a48e#file-indentxml-ps1
	[Cmdletbinding()]
    param
    (
        [xml]$Content,
        [int]$Indent
    )

	$StringWriter = New-Object System.IO.StringWriter 
	$Settings = New-Object System.XMl.XmlWriterSettings
	$Settings.Indent = $true
	$Settings.IndentChars = ' ' * $Indent
	$Settings.Encoding = [System.Text.Encoding]::UTF8
    
	$XmlWriter = [System.XMl.XmlWriter]::Create($StringWriter, $Settings)

    $Content.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush();$StringWriter.Flush() 
    $StringWriter.ToString().Replace('<?xml version="1.0" encoding="utf-16"?>','<?xml version="1.0" encoding="utf-8"?>')
}

function Get-CSharpProjects {
    <#.Synopsis
        Get the solution's C# projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-CSharpProjects -SolutionPath .\EcsShared | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath
    )
    $csProjId = '{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $csProjId
    $newCsProjId = '{9A19103F-16F7-4668-BE54-9A1E7A4F7556}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $newCsProjId
}

function Get-NuGetDbToolsConfig {
	[xml]$config = Get-Content (Get-NuGetDbToolsConfigPath)
	Return $config
}

function Get-NuGetDbToolsConfigPath {
	if ($Global:testing) {
		"TestDrive:\Configuration\NugetDbTools.config"
	} else {
		"$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
	}
}


function Get-NuGetLocalApiKey {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'ApiKey' } | % { $_.value }
}

function Get-NuGetLocalSource {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }
}

function Get-NuGetPackageVersion {
	<#.Synopsis
	Get the latest version number of the package
	.DESCRIPTION
	Retrieves the latest version number of the specified package in the local NuGet server
	.EXAMPLE
	$ver = Get-NuGetPackageVersion -PackageName 'BackOfficeAudit.Logging'
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The NuGet package name
		[string]$PackageName
	)
	$version = ''
	iex "nuget list $PackageName -Source $(Get-NuGetLocalSource)" | % {
		$nameVersion = $_ -split ' '
		if ($nameVersion[0] -eq $PackageName) {
			$version = $nameVersion[1]
		}
	}
	return $version
}

function Get-ParentSubfolder
{
	<#.Synopsis
	Search the folders in the Path for a match to the filter
	.DESCRIPTION
	Search the Path and its parents until the Filter is matched
	The path containing the successful match is returned otherwise a empty string
	.EXAMPLE
	Get-ParentSubfolder -Path . -Filter '*.sln'
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The path being tested
		[string]$Path,
        # The pattern being matched
        [string]$Filter
	)
	[string]$myPath = (Resolve-Path $Path).Path
	while ($myPath -and -not (Test-Path ([IO.Path]::Combine($myPath,$Filter)))) {
		$myPath = Split-Path $myPath
	}
	if ([string]::IsNullOrEmpty($myPath)) {
		return ''
	} else {
		 return $myPath
		}
}

function Get-PowerShellProjects {
    <#.Synopsis
        Get the solution's C# projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-PowerShellProjects -SolutionPath .\EcsShared | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath
    )
    $csProjId = '{F5034706-568F-408A-B7B3-4D38C6DB8A32}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $csProjId
}

function Get-ProjectsByType {
    <#.Synopsis
        Get the solution's projects of the specified type
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-ProjectsByType -SolutionPath .\EcsShared -ProjId '{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}' | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath,
        # The project type ID
        [string]$ProjId
    )
    [string]$sln=gc $SolutionPath | Out-String

    $nameGrouping = '(?<name>[^"]+)'
    $pathGrouping = '(?<path>[^"]+)'
    $guidGrouping = '(?<guid>[^\}]+)'
    $regex = "\r\nProject\(`"$ProjId`"\)\s*=\s*`"$nameGrouping`"\s*,\s*`"$pathGrouping`",\s*`"\{$guidGrouping\}`".*"
    $matches = ([regex]$regex).Matches($sln)

    $matches | % {
		$projName = $_.Groups['name'].Value
        $projPath = $_.Groups['path'].Value
        $projGuid = $_.Groups['guid'].Value
        New-Object -TypeName PSObject -Property @{
            Project = $projName;
            ProjectPath = $projPath;
            ProjectGuid = $projGuid
        }
    }
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
		[string]$MinorVersion = '0'

	)
	# Note: use Invoke-Expression (iex) so that git calls can be mocked in tests
	try {
		Push-Location $Path
		$majorVer = if ([string]::IsNullOrEmpty($MajorVersion)) { '0'} else { $MajorVersion }
		$minorVer = if ([string]::IsNullOrEmpty($MinorVersion)) { '0'} else { $MinorVersion }
		$latestTag = "$majorVer.$minorVer"
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			$revisions = (iex "git rev-list HEAD -- $Path").Count
		}
		else {
			$revisions = '0'
		}
		$version = "$latestTag.$revisions"
		
		if (Test-PathIsInGitRepo -Path (Get-Location)) {
			$branch = iex 'git branch' | ? { $_.StartsWith('* ') } | % { $_.Replace('* ', '') }
			if ($branch -and ($branch -ne 'master')) {
				$version += "-$branch"
			}
		}
		
		return $version
	}
	finally {
		Pop-Location
	}
}


function Get-SqlProjects {
    <#.Synopsis
        Get the solution's SQL projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-SqlProjects -SolutionPath .\EcsShared | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath
    )
    $sqlProjId = '{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $sqlProjId
}

function Import-NuGetSettings
{
	<#.Synopsis
	Import NuGet settings
	.DESCRIPTION
	Import the NuGet spec settings from the project's NuGet configuration file (<projctName>.nuget.config)
	.EXAMPLE
	Import-NuGetSettings -NugetConfigPath 'EcsShared.SharedBase.nuget.config'
	#>
    [CmdletBinding()]
    [OutputType([Collections.Hashtable])]
    param
    (
        # The project's NuGet configuration file
		[Parameter(Mandatory=$true, Position=0)]
		[string]$NugetConfigPath
	)
	$nugetSettings = New-Object -TypeName PSObject -Property @{
		nugetOptions = New-Object -TypeName PSObject -Property @{
				majorVersion = '';
				minorVersion = ''
			};
		nugetSettings = @{};
		nugetDependencies = @{}
	}

	if (Test-Path $NugetConfigPath) {
        [xml]$cfg = gc $NugetConfigPath
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
	    $projPath = Split-Path -LiteralPath $NugetConfigPath
	    $nugetSettings.nugetSettings['version'] = Get-ProjectVersion -Path $projPath -MajorVersion $nugetSettings.nugetOptions.majorVersion -minorVersion $nugetSettings.nugetOptions.minorVersion
	    $cfg.configuration.nugetDependencies.add | ? { $_ } | % {
		    $nugetSettings.nugetDependencies[$_.key] = $_.value
	    }
    }
	$nugetSettings
}

Function Out-FormattedXml {
	param (
		[xml]$Xml,
		[string]$FilePath
	)
	Format-XMLIndent $Xml -Indent 2 | Out-File $FilePath -Encoding utf8
}


function Save-CSharpProject {
<#.Synopsis
	Saves the project data to file.
.DESCRIPTION
	Saves the project data to file.
.EXAMPLE
	Save-CSharpProject -Project $proj -Path .\BackOfficeAuditPkg\BackOfficeAuditPkg.csproj
#>
    [CmdletBinding()]
    param
    (
 		# The project data
		[xml]$Project,
        # The path of the project file
		[string]$Path
	)
	Out-FormattedXml -Xml $Project -FilePath $Path
	$text = gc $Path | ? { $_ -notlike '<`?*`?>'}
	$text | Out-File $Path -Encoding utf8
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

	$spec = gc $Path
	$dep = $spec | ? { $_ -like "*<dependency id=`"$Dependency`" version=`"*`"/>*"  }
	$oldVersion = ($dep -split '"')[3]
	$newVersion = Get-NuGetPackageVersion $Dependency
	$newDep = $dep.Replace($oldVersion, $newVersion)
	$specText = $spec | Out-String
	$oldText = "<dependency id=`"$Dependency`" version=`"$oldVersion`"/>"
	$newText = "<dependency id=`"$Dependency`" version=`"$newVersion`"/>"
	$specText =  $specText.Replace($oldText, $newText)
	$specText | Out-File -FilePath $Path -Encoding utf8 -Force
}

function Set-NuspecVersion {
<#.Synopsis
	Set the project's version in the Project.nuspec file
.DESCRIPTION
	Calculates the project's version from the git repository.
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
		[string]$ProjectFolder
	)

	[xml]$cfg = gc Package.nuspec
	$oldVersion=$cfg.package.metadata.version
	$versionParts = $oldVersion.Split('.')
	$majorVersion = $versionParts[0]
	$minorVersion = $versionParts[1]
	$newVersion = Get-ProjectVersion -Path $ProjectFolder -MajorVersion $majorVersion -MinorVersion $minorVersion
	$cfgText = gc Package.nuspec | Out-String
	$oldText = "<version>$oldVersion</version>"
	$newText = "<version>$newVersion</version>"
	$cfgText =  $cfgText.Replace($oldText, $newText).TrimEnd()
	$cfgText | Out-File -FilePath .\Package.nuspec -Encoding utf8 -Force
	$newVersion
}

function Set-ProjectDependencyVersion {
<#.Synopsis
	Set the dependency's version in the project file to the latest version on the server.
.DESCRIPTION
	Fetches the dependency's latest version number and sets it in the project file.
.EXAMPLE
	Set-ProjectDependencyVersion -Path .\BackOfficeAuditPkg\BackOfficeAuditPkg.csproj -Dependency NuGetDbPacker
#>
    [CmdletBinding()]
    param
    (
        # The path of the project file
		[string]$Path,
		# The dependency name
		[string]$Dependency
	)
	$newVersion = Get-NuGetPackageVersion $Dependency
	[xml]$proj = gc $Path
	$refs = $proj.Project.ItemGroup | ? { $_.PackageReference }
	$ref = $refs.PackageReference | ? { $_.Include -eq $Dependency }
	if ($ref) {
		$ref.Version = $newVersion
	} else {
		[xml]$new = "<new><PackageReference Include=`"$Dependency`" Version=`"$newVersion`" /></new>"
		$node = $refs.AppendChild($refs.OwnerDocument.ImportNode($new.new.FirstChild, $true))
	}
	Save-CSharpProject -Project $proj -Path $Path
}

function Test-NuGetVersionExists {
	<#.Synopsis
	Test if the package version is on the server
	.DESCRIPTION
	The local NuGet repository is queried for the specific version of the specifiec package
	.EXAMPLE
	if (Test-NuGetVersionExists -Id 'EcsShared.EcsCore' -Version '1.0.28')
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The package being tested
		[string]$Id,
		[string]$Version
	)
	$exists = $false
	nuget List $Id -AllVersions -Source (Get-NuGetLocalSource) | ? {
		$_.EndsWith($Version) 
	} | % {
		$exists = $true 
	}
	return $exists
}

function Test-PathIsInGitRepo {
	<#.Synopsis
	Test if the Path is in a Git repository
	.DESCRIPTION
	Search the Path and its parents until the .git folder is found
	.EXAMPLE
	if (Test-PathIsInGitRepo -Path C:\VSTS\EcsShared\SupportRoles)
	#>
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
		# The path being tested
		[string]$Path
	)
	[string]$myPath = Get-ParentSubfolder -Path $Path -Filter '.git'
	return $myPath -ne ''
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


