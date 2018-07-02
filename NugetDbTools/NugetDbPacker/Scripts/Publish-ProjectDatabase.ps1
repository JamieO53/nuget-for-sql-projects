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
			Invoke-Trap -Command "$cmd /a:Publish /sf:`"$DacpacPath`" $db" -Message "Deploying database failed" -Fatal
		} catch {
			exit 1
		}
	} else {
		Log "SqlPackage.exe could not be found" -E
		exit 1
	}
}