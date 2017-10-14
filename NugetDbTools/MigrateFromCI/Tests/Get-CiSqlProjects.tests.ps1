if ( Get-Module MigrateFromCI) {
	Remove-Module MigrateFromCI
}
Import-Module "$PSScriptRoot\..\bin\Debug\MigrateFromCI\MigrateFromCI.psm1"

Describe "Get-CiSqlProjects" {
	Context "Content" {
		[xml] $deps = Get-CiDependenciesDocument -SolutionName 'RetailReconEFTV2'
		$dbs = Get-CiSqlProjects -DependenciesDoc $deps
		$exp = @('RetailReconEFTV2.PostilionV3', 'RetailReconEFTV2.RetailReconDB', 'RetailReconEFTV2.eftv2db')
		It "Project count" { $dbs.Count | should be $exp.Count }
		Context "Elements" {
			$exp | % {
				It $_ { $_ | should bein $dbs }
			}
		}
	}
}