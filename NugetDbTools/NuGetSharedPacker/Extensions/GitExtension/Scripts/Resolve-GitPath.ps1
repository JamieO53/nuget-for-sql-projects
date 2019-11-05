function Resolve-GitPath {
	<#.Synopsis
	Mormalizes the path
	.DESCRIPTION
	Ensures that the path matches the underlying path with a case-sensitive comparison
	.EXAMPLE
	(Resolve-GitPath c:\azuredevops\continuousintegration\nuget-for-sql-projects) -eq 'C:\AzureDevOps\ContinuousIntegration\nuget-for-sql-projects'
	#>
    [CmdletBinding()]
	[OutputType([string])]
    param (
        # The path being resolved
		[string]$Path
	)
	return (Get-Item $Path).FullName
}