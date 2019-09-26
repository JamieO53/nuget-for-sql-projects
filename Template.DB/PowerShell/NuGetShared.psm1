
function Add-DictionaryNode ($parentNode, $key, $value) {
	$dic = Add-Node -parentNode $parentNode -id 'add'
	$dic.SetAttribute('key', $key)
	$dic.SetAttribute('value', $value)
}

function Add-Node ($parentNode, $id) {
	[xml]$node = "<$id/>"
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($node.FirstChild, $true))
	$childNode
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

function Get-Caller {
	(Get-PSCallStack | Select-Object -First 3 | Select-Object -Last 1).Command
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

function Get-ExtensionPaths {
	$extensions = @{}
	Get-ToolsConfiguration | % {
		$tools = $_
		$tools.extensions.extension | % {
			$extensions[$_.name] = "$PSScriptRoot\$($_.path)"
		}
	}
	return $extensions
}

function Get-GroupNode ($parentNode, $id) {
	$gn = $parentNode.SelectSingleNode($id)
	if ($gn) {
		$gn
	} else {
		Add-Node -parentNode $parentNode -id $id
	}
}

function Get-LogPath {
    [CmdletBinding()]
	param (
		[string]$Name
	)
	$logFolder = "$(Split-Path $MyInvocation.PSScriptRoot)\Logs"
	if (-not (Test-Path $logFolder)) {
		md $logFolder | Out-Null
	}
	"$logFolder\$Name-$((Get-Date).ToString('yyyy-MM-dd-HH-mm-ss-fff')).log"
}

function Get-NuGetCachePaths {
	[string[]]$paths = @("$env:userprofile\.nuget\packages", 'Microsoft Visual Studio Offline Packages')
	$paths
}

function Get-NuGetContentFolder {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'ContentFolder' } | % { $_.value }
}

function Get-NuGetDbToolsConfig {
	[xml]$config = Get-Content (Get-NuGetDbToolsConfigPath)
	Return $config
}

function Get-NuGetDbToolsConfigPath {
	if ($Global:testing) {
		"TestDrive:\Configuration\NugetDbTools.config"
	} else {
		if (Test-Path "$PSScriptRoot\..\JamieO53\NugetDBTools\NugetDbTools.config") {
			"$PSScriptRoot\..\JamieO53\NugetDBTools\NugetDbTools.config"
		} elseif (Test-Path "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config") {
			"$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config"
		} else {
			Log "Unable to find NuGetDbTools configuration"
		}
	}
}


function Get-NuGetLocalApiKey {
	$config = Get-NuGetDbToolsConfig
	$config.configuration.nugetLocalServer.add | ? { $_.key -eq 'ApiKey' } | % { $_.value }
}

function Get-NuGetLocalPushSource {
	$config = Get-NuGetDbToolsConfig
	$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'PushSource' } | % { $_.value }
	if ([string]::IsNullOrEmpty($source)) {
		$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'Source' } | % { $_.value }
	}
	$source
}

function Get-NuGetLocalPushTimeout {
	$config = Get-NuGetDbToolsConfig
	$source = $config.configuration.nugetLocalServer.add | ? { $_.key -eq 'PushTimeout' } | % { $_.value }
	if ([string]::IsNullOrEmpty($source)) {
		$source = 900
	}
	$source
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
    [string]$sln=if ($SolutionPath -and (Test-Path $SolutionPath)) {gc $SolutionPath | Out-String} else {''}

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

function Get-ToolsConfiguration {
	$configPath = "$PSScriptRoot\..\PackageTools\PackageTools.root.config"
	if (-not (Test-Path $configPath)) {
		## Release - look parent folder
		$configPath = "$PSScriptRoot\..\PackageTools.root.config"
		if (-not (Test-Path $configPath)) {
			## Testing - look in test scripts folder
			$configPath = "$PSScriptRoot\..\..\..\Tests\PackageTools.root.config"
			if (-not (Test-Path $configPath)) {
				Log 'Unable to find Package Tools configuration: PackageTools.root.config' -Error
				Throw 'Missing configuration'
			}
		}
	}
	$tools = @()
	if (Test-Path $configPath) {
		[xml]$config = gc $configPath
		if ($config.tools) {
			$tools += $config.tools
		}
	}
	$tools
}

function Import-Extensions {
    $extensions = Get-ExtensionPaths
    $extensions.Keys | % {
        $extension = $_
        $extensionPath = $extensions[$_]
        if (-not (Get-Module $extension -All)) {
            if (Test-Path $extensionPath) {
                Import-Module $extensionPath -Global -DisableNameChecking
            } else {
                throw "Unable to import extension $extension"
            }
        }
    }
}

function Invoke-Trap {
    [CmdletBinding()]
	param (
		[string]$Command,
		[string]$Message,
		[switch]$Fatal
	)
	try {
		iex "$Command 2> .\errors.txt"
		if ($LASTEXITCODE -ne 0) {
			$caller = Get-Caller
			Log $Message -Error -taskStep $caller
			$errors = gc .\errors.txt
			$errors | % {
				Log $_ -Error -taskStep $caller -allowLayout
			}
			if ($Fatal) {
				throw $Message
			}
		}
	} finally {
		if (Test-Path .\errors.txt) {
			Remove-Item .\errors.txt
		}
	}
}

[String]$script:logPath=$null
function Log {
    [CmdletBinding()]
	param (
		[string]$logMsg=$null,
		[string]$task=$null,
		[string]$taskStep=$null,
		[string]$fg=$null,
		[switch]$Warn, [switch]$Error, [switch]$hilite, [switch]$stdoutOnly, [switch]$allowLayout
	)
	if ([string]::IsNullOrEmpty($task)) {
		$task = [IO.Path]::GetFileNameWithoutExtension((Get-PSCallStack | Select-Object -Last 1).ScriptName)
	}
	if ([string]::IsNullOrEmpty($taskStep)) {
		$taskStep = Get-Caller
	}

	$level='I'
	if ($hilite)
	{
		$level+='!'
	}

	if (-not $allowLayout -and [string]::IsNullOrEmpty($logMsg))
	{
		$logMsg="Log message argument expected!"
		if (-not $Error)
		{
			$warn=$true
		}
	}
	
	if ($Error)
		{$level='E'; $fg='red'}
	elseif ($Warn)
		{$level='W'; if ($debug) {$fg='magenta'} else {$fg='yellow'}}
	elseif ($hilite)
		{if ($debug) {$fg='black'} else {$fg='white'}}
	elseif ($debug)
		{$fg='black'} 
	elseif (-not $fg)
		{$fg='gray'}

	$msg = "[$task][$taskStep][$level] $logMsg".Replace('[]','')
	if (-not $stdoutOnly) {
		if ([string]::IsNullOrEmpty($script:logPath)) {
			$log = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)
			$script:logPath = Get-LogPath $log
		}
		Out-File $script:logPath -InputObject $msg -Encoding ascii -Append -NoClobber -Width 1024
	}
	Write-Host $msg -ForegroundColor $fg
}

Function Out-FormattedXml {
	param (
		[xml]$Xml,
		[string]$FilePath
	)
	Format-XMLIndent $Xml -Indent 2 | Out-File $FilePath -Encoding utf8
}


function Publish-NuGetPackage {
	<#.Synopsis
	Pushes the package to the 
	.DESCRIPTION
	Exports the settings to the project's NuGet configuration file
	.EXAMPLE
	Publish-NuGetPackage -PackagePath "$projDir\$id.$version.nupkg"
	#>
    [CmdletBinding()]
    param
    (
        # The location of the package being published
        [string]$PackagePath
	)
	$localSource = Get-NuGetLocalPushSource
	if (Test-Path $localSource) {
		nuget add $PackagePath -Source $localSource -NonInteractive
	} else {
		$apiKey = Get-NuGetLocalApiKey
		$timeout = Get-NuGetLocalPushTimeout
		Invoke-Trap "nuget push $PackagePath -ApiKey `"$apiKey`" -Source $localSource -Timeout $timeout" -Message "Unable to push $(Split-Path $PackagePath -Leaf)" -Fatal
	}
}

function Remove-Node ($parentNode, $id){
	$childNode = $parentNode.SelectSingleNode($id)
	$parentNode.RemoveChild($childNode) | Out-Null
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

function Set-NodeText ($parentNode, $id, [String]$text){
		[xml.XmlNode]$childNode | Out-Null
		$parentNode.SelectSingleNode($id) |
			where { $_ } |
			foreach {
				$childNode = $_
			}
		if (-not $childNode) {
			$newNode = Add-Node -parentNode $parentNode -id $id
			$newNode.InnerText = $text
		}
		else
		{
			$childNode.InnerText = $text
		}
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
		$newRef = Add-Node -parentNode $refs -id PackageReference
		$newRef.SetAttribute('Include', $Dependency);
		$newRef.SetAttribute('Version', $newVersion);
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
	nuget List $Id -AllVersions -Source (Get-NuGetLocalSource) -PreRelease -NonInteractive | ? {
		$_.Equals("$Id $Version") 
	} | % {
		$exists = $true 
	}
	return $exists
}


