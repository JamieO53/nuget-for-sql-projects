param(
	[string]$Path
)
if (Get-Module DbSolutionBuilder) {
    Remove-Module DbSolutionBuilder
}
Import-Module .\PowerShell\DbSolutionBuilder.psm1
$params = gc $Path
New-DbSolution -Parameters $params
