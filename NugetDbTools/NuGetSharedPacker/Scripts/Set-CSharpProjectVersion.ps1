function Set-CSharpProjectVersion {
	<#.Synopsis
	Set the assembly versions of all the solution's assemblies
	.DESCRIPTION
    Edits all the solution's csproj and sqlproj files 
	.EXAMPLE
	Set-CSharpProjectVersion -SolutionPath C:\VSTS\Batch\Batch.sln -Version 1.0.123
	#>
    [CmdletBinding()]
    param
    (
        # The location of .sln file of the solution being updated
        [string]$SolutionPath,
		# The build package version
		[string]$Version
	)
	$solutionFolder = Split-Path $SolutionPath
	$regex = '(Assembly.*Version\(\")([\d\.]*)(\"\))'
	(Get-CSharpProjects $SolutionPath) + (Get-SqlProjects $SolutionPath) | ForEach-Object {
		$projPath = "$slnFolder\$($_.ProjectPath)"
		$projFolder = Split-Path $projPath
		$infoPath = "$projFolder\Properties\AssemblyInfo.cs"
		if (Test-Path $infoPath) {
			$info = Get-Content $infoPath
			$info = $info -replace $regex,"`${1}$Version`${3}"
			$info | Out-File $infoPath
		}
		[xml]$proj = Get-Content -Path $projPath
		$parentNode = $proj.Project.PropertyGroup | Where-Object { $_.ApplicationVersion }
		if ($parentNode) {
			Set-NodeText -parentNode $parentNode -id 'ApplicationVersion' -text $Version
			$proj = $proj.OuterXML.Replace(' xmlns=""','') # I don't know where this comes from
			Out-FormattedXml -Xml $proj -FilePath $projPath
		}
	}
}