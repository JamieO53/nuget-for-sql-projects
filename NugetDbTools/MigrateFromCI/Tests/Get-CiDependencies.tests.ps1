if ( Get-Module MigrateFromCI) {
	Remove-Module MigrateFromCI
}
Import-Module "$PSScriptRoot\..\bin\Debug\MigrateFromCI\MigrateFromCI.psm1"

Describe "Get-CiDependenciesDocument" {
	Context "Exists" {
		It "Runs" {
			Get-CiDependenciesDocument -SolutionName RetailReconEFTV2 | should not benullorempty
		}
	}
	Context "Contents" {
		[xml]$deps = Get-CiDependenciesDocument -SolutionName RetailReconEFTV2
		Context Component {
			It name { $deps.Component.name | should be 'RetailReconEFTV2' }
			It shortName { $deps.Component.shortName | should be 'RREFT2' }
		}
	}
}