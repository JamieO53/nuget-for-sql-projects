function New-DbSolution {
	<#.Synopsis
	Create a new SQL database solution
	.DESCRIPTION
	Creates a Visual Studio solution for SQL projects with the standard components

	The result is the location of the new solution
	.EXAMPLE
	[xml]$params = gc .\DbSolution.xml
	New-DbSolution -Parameters $params
	#>
    [CmdletBinding()]
    [OutputType([string])]
    param
    (
		# The DB Solution Builder parameters
		[xml]$Parameters
	)
	$templateFolder = "$env:TEMP\$([Guid]::NewGuid())\template"
	mkdir $templateFolder | Out-Null
	nuget install NuGetDbPacker.DbTemplate -source (Get-NuGetLocalSource) -outputDirectory $templateFolder -ExcludeVersion

	$solutionLocation = $Parameters.dbSolution.parameters.location
	$solutionName = $Parameters.dbSolution.parameters.name
	$slnFolder = "$solutionLocation\$solutionName"
    $slnPath = "$slnFolder\$($SolutionName).sln"
	$pkgProjectPath = "$slnFolder\$($SolutionName)Pkg\$($SolutionName)Pkg.csproj"

	mkdir "$slnFolder\$($SolutionName)Pkg" | Out-Null
	mkdir "$slnFolder\PackageTools"

	$templatePath = "$templateFolder\NuGetDbPacker.DbTemplate\Template"
	$toolsPath = "$templateFolder\NuGetDbPacker.DbTemplate\PackageTools"
	copy "$templatePath\Template.DBPkg\Class1.cs" "$slnFolder\$($SolutionName)Pkg"
	copy "$templatePath\Template.DBPkg\Template.DBPkg.csproj" $pkgProjectPath
	copy "$templatePath\Template.DB.sln" $slnPath
	copy "$toolsPath\*" "$slnFolder\PackageTools"
	Set-ProjectDependencyVersion -Path $pkgProjectPath -Dependency NuGetDbPacker
	$Parameters.dbSolution.dependencies.dependency | % {
		Set-ProjectDependencyVersion -Path $pkgProjectPath -Dependency $_.Id
	}

	iex "$slnFolder\PackageTools\Bootstrap.ps1"

	$newGuid = [Guid]::NewGuid().ToString().ToUpperInvariant()
	$sln = gc $slnPath | Out-String
	$sln = $sln.Replace('Template.DBPkg', "$($SolutionName)Pkg").Replace('1D72F9F5-2ED0-4157-9EF8-903203AA428C', $newGuid)
	$sln | Out-File -FilePath $slnPath -Encoding utf8

	if (-not (Get-Module NugetDbPacker)) {
		Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"
	}

	Get-SolutionContent -SolutionPath $slnPath

	$sln = gc $slnPath | Out-String
	$sln = Set-SqlProjectInSolution -Parameters $Parameters -SolutionFolder $slnFolder -TemplateFolder $templatePath -SolutionFile $sln -PkgProjectPath $pkgProjectPath
	$sln | Out-File -FilePath $slnPath -Encoding utf8
	#iex "$slnFolder\PackageTools\Get-PackageContent.ps1"

	#Set-SqlProjectDependenciesInSolution -SolutionPath $slnPath
	Return $slnFolder
}