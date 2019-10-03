function Get-ProjectDependencyVersion {
<#.Synopsis
	Get the dependency's version
.DESCRIPTION
	Takes the project's version from the Pkg project if available, otherwise uses the old version
.EXAMPLE
	$ver = Get-ProjectDependencyVersion -Path "$slnFolder\$($slnName)Pkg\$($slnName)Pkg" -Dependency Tools -OldVersion '1.0.418'
#>
    [CmdletBinding()]
    param
    (
        # The solution path
		[string]$SolutionPath,
		# The dependency
		[string]$Dependency,
		#The configuration version used as default
		[string]$OldVersion

	)
	$version = $OldVersion
	$slnFolder = Split-Path $SolutionPath
	Get-PkgProjects -SolutionPath $SolutionPath | ForEach-Object {
		$projPath = [IO.Path]::Combine($slnFolder, $_.ProjectPath)
		[xml]$proj = Get-Content $projPath
		$refs = $proj.Project.ItemGroup | Where-Object { $_.PackageReference }
		$refs.PackageReference | Where-Object { $_.Include -eq $Dependency } | ForEach-Object {
			$version = $_.Version
		}
	}
		
	return $version
}

