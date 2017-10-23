if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

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