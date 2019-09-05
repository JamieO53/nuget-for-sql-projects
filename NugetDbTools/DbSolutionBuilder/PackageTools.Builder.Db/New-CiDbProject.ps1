param(
	[string]$Path
)
if (Get-Module DbSolutionBuilder) {
    Remove-Module DbSolutionBuilder
}
Import-Module .\PowerShell\DbSolutionBuilder.psd1 -Global -DisableNameChecking
$params = gc $Path
New-DbSolution -Parameters $params
