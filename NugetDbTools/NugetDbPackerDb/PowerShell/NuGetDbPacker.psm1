if (-not (Get-Module NugetSharedPacker -All)) {
	Import-Module "$PSScriptRoot\NugetSharedPacker.psd1"
}

function Add-DbFileNode ($parentNode) {
	$files = Get-GroupNode -parentNode $parentNode -id 'files'
	$file = Add-Node -parentNode $files -id file
	$file.SetAttribute('src', 'content\Databases\**')
	$file.SetAttribute('target', 'Databases')
}

function Enable-CLR{
	<#.Synopsis
	Enable CLR on the specified server
	.DESCRIPTION
    Finds the .publish.xml file needed to publish the project. This will be "$projectFolder\$projectName.publish.xml" unless
	there is an override of the form "$projectFolder\$projectName.OVERRIDE.publish.xml" which is returned instead. The overrides
	are, in order of priority:
	
	- the specified override
	- The computer host name - not to be used for build servers
	- The host type - DEV, BUILD
	- The repository branch

	.EXAMPLE
	Enable-CLR -ProfilePath C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.profile.xml
	#>
    [CmdletBinding()]
    param
    (
        # The location of the .profile.xml file being published
		[string]$ProfilePath
	)
	
	if(-not (Get-InstalledModule SqlServer)) {
		Install-Module SqlServer
	}
	Import-Module SqlServer
	[xml]$doc = gc $ProfilePath
	[string]$connectionString = $doc.Project.PropertyGroup.TargetConnectionString
	$query = @'
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO
sp_configure 'show advanced options', 0;
GO
RECONFIGURE;
GO
'@
	Invoke-Sqlcmd -ConnectionString $connectionString -Query $query
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

function Format-ProjectDatabaseParameters {
	<#.Synopsis
	Format the SqlCommand CLI parameters to publish the DB project dacpac
	.DESCRIPTION
    Formats the parameters to publish the dacpac using profile if available and override parameters.
	.EXAMPLE
	Publish-ProjectDatabase -PublishTemplate C:\VSTS\EcsShared\SupportRoles\EcsShared.SupportRoles.publish.xml
	#>
    [CmdletBinding()]
    [OutputType([string])]
	param
    (
        # The location of .dacpac file being published
		[string]$DacpacPath,
        # The location of the profile (.publish.xml file being) with deployment options
        [string]$ProfilePath,
		# Parameters overriding profile settings
		# Format according to SqlPackage CLI https://docs.microsoft.com/en-us/sql/tools/sqlpackage?view=sql-server-2017
		[string[]]$Parameters
	)

	if (-not $DacpacPath) {
		throw 'No DacPac was specified'
	}
	if (-not (Test-Path $DacpacPath)) {
		throw "The DacPac does not exist at $DacpacPath"
	}
	if ($Parameters) {
		$params = [string]::Join(' ', $Parameters)
	} else {
		$params = ''
	}
	if ($ProfilePath) {
		if (Test-Path $ProfilePath) {
			[string]$db = "/pr:`"$ProfilePath`" $params"
		} else {
			throw "The Profile does not exist at $ProfilePath"
		}
	} else {
		if (-not ($params.Contains('/p:CreateNewDatabase'))) {
			$params += ' /p:CreateNewDatabase=True'
		}
		if (-not ($params.Contains('/tdn:') -or $params.Contains('/TargetDatabaseName:'))) {
			$projectName = [IO.Path]::GetFileNameWithoutExtension($DacpacPath)
			[string]$db = "/tdn:`"$projectName`" $params"
		} else {
			[string]$db = $params
		}
	}
	$db
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
            if ($env:SYSTEM_SERVERTYPE -ne 'Hosted') {
				Publish-NuGetPackage -PackagePath $nugetPackage
				Remove-NugetFolder $nugetFolder
			}
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
        [string]$ProfilePath,
		# Parameters overriding profile settings
		# Format according to SqlPackage CLI https://docs.microsoft.com/en-us/sql/tools/sqlpackage?view=sql-server-2017
		[string[]]$Parameters
	)
	[string]$cmd = Find-SqlPackagePath
	if ($cmd) {
		try {
			$params = Format-ProjectDatabaseParameters -DacpacPath $DacpacPath -ProfilePath $ProfilePath -Parameters $Parameters
	
			Log "Publishing $DacpacPath using $ProfilePath"
			Invoke-Trap -Command "& `"$cmd`" /a:Publish /sf:`"$DacpacPath`" $params" -Message "Deploying database failed" -Fatal
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

function Publish-SSASCubeDatabase {
	param (
		[string]$CubeFolder,
		[string]$CubeName,
		[string]$ConfigSharedFolder,
		[string]$ConfigFolder,
		[string]$DatabaseName,
		[string]$DeploymentError
	)
	if (Test-Path "$ConfigFolder") {
		Update-SSASCubeAsdatabaseFile `
			-SSASCubeAsdatabasePath "$CubeFolder\$CubeName.asdatabase" `
			-DeploymentTargetConfigPath "$ConfigFolder\$CubeName.deploymenttargets"

		Update-SSASCubeDeploymentOptions `
			-SSASCubeDeploymentOptionsPath "$CubeFolder\$CubeName.deploymentoptions" `
			-DeploymentOptionsConfigPath "$ConfigSharedFolder\default.deploymentoptions"

		Update-SSASCubeDeploymentTarget `
			-SSASCubeDeploymentTargetsPath "$CubeFolder\$CubeName.deploymenttargets" `
			-DeploymentTargetConfigPath "$ConfigFolder\$CubeName.deploymenttargets"

		Update-SSASCubeDataSource `
			-SSASCubeConfigSettingsPath "$CubeFolder\$CubeName.configsettings" `
			-DataSourceConfigPath "$ConfigFolder\DataSources.configsettings"

		[string]$TargetServerVersion = "2016"

		if(Test-Path -Path "$ConfigFolder\AdditionalSettings.xml") {
		    [xml]$SSASCubeAdditionalSettingsFile = Get-Content "$ConfigFolder\AdditionalSettings.xml"
			if (-not $SSASCubeAdditionalSettingsFile.Settings.Server.Version) {
				Write-Host "SSAS Target server version variable not defined, defaulting to $TargetServerVersion" -fore red
			} else {
				$TargetServerVersion = $SSASCubeAdditionalSettingsFile.Settings.Server.Version;
			}
		} else {
		    Write-Host "Additional settings file was not defined for this target deployment channel" -fore yellow
		}
		
		Invoke-Trap -Command ".\Microsoft.AnalysisServices.Deployment.ps1 `"$CubeFolder\$CubeName.asdatabase`" `"$DatabaseName`" `"$TargetServerVersion`"" -Message $DeploymentError -Fatal
	}
}

function Report-PublishProjectDatabase {
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
        [string]$ProfilePath,
		# The destination of the deploy report
		[string]$OutputPath,
		# Parameters overriding profile settings
		# Format according to SqlPackage CLI https://docs.microsoft.com/en-us/sql/tools/sqlpackage?view=sql-server-2017
		[string[]]$Parameters
	)
	[string]$cmd = Find-SqlPackagePath
	if ($cmd) {
		try {
			$params = Format-ProjectDatabaseParameters -DacpacPath $DacpacPath -ProfilePath $ProfilePath -Parameters $Parameters
	
			Log "Publishing $DacpacPath using $ProfilePath"
			Invoke-Trap -Command "& `"$cmd`" /a:DeployReport /sf:`"$DacpacPath`" /op:`"$outputPath`" $params" -Message "Reporting the database deployment failed" -Fatal
		} catch {
			Log "SqlPackage.exe failed: $_" -Error
			exit 1
		}
	} else {
		Log "SqlPackage.exe could not be found" -E
		exit 1
	}}

function Update-SSASCubeAsdatabaseFile {
	param (
		[string]$SSASCubeAsdatabasePath,
		[string]$DeploymentTargetConfigPath
	)
	
	try {
		if ([string]::IsNullOrEmpty($SSASCubeAsdatabasePath)) {
			Write-Host "$SSASCubeAsdatabasePath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeAsdatabaseFileName = [IO.Path]::GetFileName($SSASCubeAsdatabasePath)
		Write-Host "Updating $SSASCubeAsdatabaseFileName..."

		[xml]$SSASCubeAsdatabaseFile = Get-Content "$SSASCubeAsdatabasePath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeAsdatabaseFile.Database.ID = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeAsdatabaseFile.Database.Name = $deploymentTargetConfigFile.DeploymentTarget.Database

		$SSASCubeAsdatabaseFile.Save("$SSASCubeAsdatabasePath")

		Write-Host "$SSASCubeAsdatabaseFileName datasource updated..."
	} catch {
		Log "Update-SSASCubeAsdatabaseFile failed: $_" -Error
	}
}

function Update-SSASCubeDataSource {
	param (
		[string]$SSASCubeConfigSettingsPath,
		[string]$DataSourceConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeConfigSettingsPath)) {
			Write-Host "$SSASCubeConfigSettingsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DataSourceConfigPath)) {
			Write-Host "$DataSourceConfigPath not found" -fore red
			exit 1
		}

		$SSASCubeConfigSettingsFileName = [IO.Path]::GetFileName($SSASCubeConfigSettingsPath)
		Write-Host "Updating $SSASCubeConfigSettingsFileName..."
		
		[xml]$SSASCubeConfigSettingsFile = Get-Content "$SSASCubeConfigSettingsPath"
		[xml]$dataSourceConfigFile = Get-Content "$DataSourceConfigPath"

		$configSettingsDataSources = $SSASCubeConfigSettingsFile.ConfigurationSettings.Database.DataSources.DataSource
		
		foreach ($dataSource in $dataSourceConfigFile.DataSources.DataSource) {
			$configSettingDataSource = $configSettingsDataSources | Where-Object { $_.ID -eq $dataSource.ID }
			$configSettingDataSource.ConnectionString = $dataSource.ConnectionString
		}

		$SSASCubeConfigSettingsFile.Save("$SSASCubeConfigSettingsPath")

		Write-Host "$SSASCubeConfigSettingsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDetails failed: $_" -Error
	}
}

function Update-SSASCubeDeploymentOptions {
	param (
		[string]$SSASCubeDeploymentOptionsPath,
		[string]$DeploymentOptionsConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentOptionsPath)) {
			Write-Host "$SSASCubeDeploymentOptionsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentOptionsConfigPath)) {
			Write-Host "$DeploymentOptionsConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentOptionsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentOptionsPath)
		Write-Host "Updating $SSASdeploymentOptionsFileName..."

		[xml]$SSASCubeDeploymentOptionsFile = Get-Content "$SSASCubeDeploymentOptionsPath"
		[xml]$deploymentOptionsConfigFile = Get-Content "$DeploymentOptionsConfigPath"
		
		$SSASCubeDeploymentOptions = $SSASCubeDeploymentOptionsFile.DeploymentOptions.ChildNodes
		$deploymentOptions = $deploymentOptionsConfigFile.DeploymentOptions.ChildNodes

		foreach ($deploymentOption in $deploymentOptions) {
			$SSASCubeDeploymentOption = $SSASCubeDeploymentOptions | Where-Object { $_.Name -eq $deploymentOption.Name }

			if ($null -ne $SSASCubeDeploymentOption) {
				$SSASCubeDeploymentOption.InnerText = $deploymentOption.InnerText
			}
		}

		$SSASCubeDeploymentOptionsFile.Save("$SSASCubeDeploymentOptionsPath")

		Write-Host "$SSASdeploymentOptionsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentOptions failed: $_" -Error
	}
}

function Update-SSASCubeDeploymentTarget {
	param (
		[string]$SSASCubeDeploymentTargetsPath,
		[string]$DeploymentTargetConfigPath
	)

	try {
		if ([string]::IsNullOrEmpty($SSASCubeDeploymentTargetsPath)) {
			Write-Host "$SSASCubeDeploymentTargetsPath not found" -fore red
			exit 1
		}

		if ([string]::IsNullOrEmpty($DeploymentTargetConfigPath)) {
			Write-Host "$DeploymentTargetConfigPath not found" -fore red
			exit 1
		}

		$SSASdeploymentTargetsFileName = [IO.Path]::GetFileName($SSASCubeDeploymentTargetsPath)
		Write-Host "Updating $SSASdeploymentTargetsFileName..."

		[xml]$SSASCubeDeploymentTargetsFile = Get-Content "$SSASCubeDeploymentTargetsPath"
		[xml]$deploymentTargetConfigFile = Get-Content "$DeploymentTargetConfigPath"

		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Database = $deploymentTargetConfigFile.DeploymentTarget.Database
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.Server = $deploymentTargetConfigFile.DeploymentTarget.Server
		$SSASCubeDeploymentTargetsFile.DeploymentTarget.ConnectionString = $deploymentTargetConfigFile.DeploymentTarget.ConnectionString

		$SSASCubeDeploymentTargetsFile.Save("$SSASCubeDeploymentTargetsPath")

		Write-Host "$SSASdeploymentTargetsFileName datasource updated..."
	}
	catch {
		Log "Update-SSASCubeDeploymentTarget failed: $_" -Error
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

	Initialize-Package -ProjectPath $ProjectPath -NugetSettings $nugetSettings -SolutionPath $SolutionPath
	mkdir "$nugetPath\content\Databases" | Out-Null
	Import-NuGetDb -ProjectPath $ProjectPath -ProjDbFolder "$projectFolder\Databases" -NugetDbFolder "$nugetPath\content\Databases" -NugetSpecPath "$nugetPath\Package.nuspec"
	Compress-Package -NugetPath $nugetPath
}


