if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"

Describe "Format-ProjectDatabaseParameters" {
	$dbFolder = 'TestDrive:\Databases'
	$dacpacPath = "$dbFolder\db.dacpac"
	$profilePath = "$dbFolder\db.profile.xml"

	Context "Exists" {
		It "Can Run" {
			Test-Path Function:\Format-ProjectDatabaseParameters | should be $true
		}
	}
	Context "DacPac conditions" {
		It "The dacpac is required" {
			{ Format-ProjectDatabaseParameters } | should -Throw "No DacPac was specified"
		}
		It "The dacpac must exist" {
			{ Format-ProjectDatabaseParameters -DacpacPath $dacpacPath } | should -Throw "The DacPac does not exist at $dacpacPath"
		}
	}
	Context "No profile specified" {
		mkdir $dbFolder
		'DacPac content' | sc -Path $dacpacPath
		It "Only the dacpac is specified" {
			(Format-ProjectDatabaseParameters -DacpacPath $dacpacPath).Trim() | should be '/tdn:"db"  /p:CreateNewDatabase=True'
		}
		It "The database should not be recreated" {
			(Format-ProjectDatabaseParameters -DacpacPath $dacpacPath -Parameters /p:CreateNewDatabase=False).Trim() | should be '/tdn:"db" /p:CreateNewDatabase=False'
		}
		It "The dacpac and database name are specified" {
			(Format-ProjectDatabaseParameters -DacpacPath $dacpacPath -Parameters '/tdn:NewDB').Trim() | should be '/tdn:NewDb /p:CreateNewDatabase=True'
		}
	}
	Context "A Profile specified" {
		mkdir $dbFolder
		'DacPac content' | sc -Path $dacpacPath
		'Profile content' | sc -Path $profilePath
		It "Existing dacpac and profile files are specified" {
			(Format-ProjectDatabaseParameters -DacpacPath $dacpacPath -ProfilePath $profilePath).Trim() | should be "/pr:`"$ProfilePath`""
		}
		It "Existing dacpac and nonexistent profile files are specified" {
			{ Format-ProjectDatabaseParameters -DacpacPath $dacpacPath -ProfilePath "$profilePath.txt" } | should -Throw "The Profile does not exist at $profilePath.txt"
		}
		It "Database name override" {
			(Format-ProjectDatabaseParameters -DacpacPath $dacpacPath -ProfilePath $profilePath -Parameters '/TargetDatabaseName:NewDB').Trim() |
				should be "/pr:`"$ProfilePath`" /TargetDatabaseName:NewDB"
		}
	}
}