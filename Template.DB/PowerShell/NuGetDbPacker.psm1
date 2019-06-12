if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module "$PSScriptRoot\NugetSharedPacker.psd1"
}

function Add-DbFileNode ($parentNode) {
	$files = Get-GroupNode -parentNode $parentNode -id 'files'
	$file = Add-Node -parentNode $files -id file
	$file.SetAttribute('src', 'content\Databases\**')
	$file.SetAttribute('target', 'Databases')
}

function Find-PublishProfilePath {
	<#.Synopsis
	Find the project's publish template if any
	.DESCRIPTION
    Finds the .publish.xml file needed to publish the project. This will be "$projectFolder\$projectName.publish.xml" unless
	there is an override of the form "$projectFolder\$projectName.OVERRIDE.publish.xml" which is returned instead. The overrides
	are, in order of priority:
	
	- the specified override
	- The computer host name - not to be used for build servers
	- The host type - DEV, BUILD
	- The repository branch

	.EXAMPLE
	Find-PublishProfilePath -ProjectPath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .sqlproj file being published
		[string]$ProjectPath,
		# The specific override
		[string]$Override = ''
	)

	$suffix = 'publish.xml'
	if (Test-IsRunningBuildAgent) {
		$hostType ='BUILD'
	} else {
		$hostType = 'DEV'
	}

	$path = [IO.Path]::ChangeExtension($ProjectPath, '.publish.xml')
	
	$overrides = @($Override, $Host.Name, $hostType, (Get-Branch))
	$overrides | ? {
		-not [string]::IsNullOrEmpty($_) 
	} | % {
		[IO.Path]::ChangeExtension($ProjectPath, ".$_.publish.xml")
	} | ? {
		Test-Path $_
	} | select -First 1 | % {
		$path = $_
	}
	$path
}

function Find-SqlPackagePath {
	[IO.FileInfo]$info
	ls "$env:ProgramFiles*\Microsoft Visual Studio\*\*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
		sort -Property FullName -Descending |
		select -First 1 | % {
			$info = $_
		}
	if ($info -eq $null)  {
		ls "$env:ProgramFiles*\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe" |
			sort -Property FullName -Descending |
			select -First 1 | % {
			$info = $_
		}
	}
	if ($info -eq $null)  {
		ls "$env:ProgramFiles*\Microsoft Visual Studio*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
			sort -Property FullName -Descending |
			select -First 1 | % {
			$info = $_
		}
	}
    if ($info) {
		return $info.FullName.Trim()
	} else {
		return $null
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
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath
	)
    $configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
    $projFolder = Split-Path $ProjectPath -Resolve
    $nugetFolder = [IO.Path]::Combine($projFolder, 'NuGet')
    if (Test-Path $configPath)
    {
        $settings = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $SolutionPath
        $id = $settings.nugetSettings.Id
        $version = $settings.nugetSettings.version
        if (-not (Test-NuGetVersionExists -Id $id -Version $version)) {
            $nugetPackage = [IO.Path]::Combine($nugetFolder, "$id.$version.nupkg")
            Initialize-DbPackage -ProjectPath $ProjectPath -SolutionPath $SolutionPath
            Publish-NuGetPackage -PackagePath $nugetPackage
            Remove-NugetFolder $nugetFolder
        }
    }
}

function Publish-ProjectDatabase {
	<#.Synopsis
	Publish the DB project dacpac
	.DESCRIPTION
    Publishes the dacpac as specified by the publish template.
	.EXAMPLE
	Publish-ProjectDatabase -PublishTemplate C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.publish.xml
	#>
    [CmdletBinding()]
    param
    (
        # The location of .dacpac file being published
		[string]$DacpacPath,
        # The location of the profile (.publish.xml file being) with deployment options
        [string]$ProfilePath
	)
	[string]$cmd = Find-SqlPackagePath
	if ($cmd) {
		try {
	
			if ($ProfilePath -and (Test-Path $ProfilePath)) {
				[string]$db = "/pr:`"$ProfilePath`""
			} else {
				$projectName = [IO.Path]::GetFileNameWithoutExtension($DacpacPath)
				[string]$db = "/tdn:`"$projectName`" /p:CreateNewDatabase=True"
			}
	
			Log "Publishing $DacpacPath using $ProfilePath"
			Invoke-Trap -Command "& `"$cmd`" /a:Publish /sf:`"$DacpacPath`" $db" -Message "Deploying database failed" -Fatal
		} catch {
			Log "SqlPackage.exe failed: $_" -Error
			exit 1
		}
	} else {
		Log "SqlPackage.exe could not be found" -E
		exit 1
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
        [string]$projectPath = [IO.Path]::Combine($solutionFolder, $_.ProjectPath)
        Publish-DbPackage -ProjectPath $projectPath -SolutionPath $SolutionPath
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
        [string]$ProjectPath,
		# The solution file
		[string]$SolutionPath
	)
	$projectFolder = Split-Path -LiteralPath $ProjectPath -Resolve
	$nugetPath = Join-Path -Path $projectFolder -ChildPath 'Nuget'
	$configPath = [IO.Path]::ChangeExtension($ProjectPath, '.nuget.config')
	$nugetSettings = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $SolutionPath

	Initialize-Package -ProjectPath $ProjectPath -NugetSettings $nugetSettings
	mkdir "$nugetPath\content\Databases" | Out-Null
	Import-NuGetDb -ProjectPath $ProjectPath -ProjDbFolder "$projectFolder\Databases" -NugetDbFolder "$nugetPath\content\Databases" -NugetSpecPath "$nugetPath\Package.nuspec"
	Compress-Package -NugetPath $nugetPath
}


