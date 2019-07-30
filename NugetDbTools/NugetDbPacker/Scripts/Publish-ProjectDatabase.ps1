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
		[string[]]$parameters
	)
	[string]$cmd = Find-SqlPackagePath
	if ($cmd) {
		try {
			if ($parameters) {
				$params = [string]::Join(' ', $parameters)
			} else {
				$params = ''
			}
			if ($ProfilePath -and (Test-Path $ProfilePath)) {
				[string]$db = "/pr:`"$ProfilePath`" $params"
			} else {
				if (-not ($params.Contains('/p:CreateNewDatabase'))) {
					$params += ' /p:CreateNewDatabase=True"'
				}
				$projectName = [IO.Path]::GetFileNameWithoutExtension($DacpacPath)
				[string]$db = "/tdn:`"$projectName`" $params"
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