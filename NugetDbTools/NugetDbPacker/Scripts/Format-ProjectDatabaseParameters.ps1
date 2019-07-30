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