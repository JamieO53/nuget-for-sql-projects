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