if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

$location = 'TestDrive:\Solutions'
$name = 'TestSolution'
[xml]$params = @"
<dbSolution>
	<parameters>
		<location>$location</location>
		<name>$name</name>
	</parameters>
</dbSolution>
"@
Describe "New-DbSolution" {
	Context "Temporary folder" {
		$temp = New-DbSolution -Parameters $params
		It "Exists" {

		}
	}
}