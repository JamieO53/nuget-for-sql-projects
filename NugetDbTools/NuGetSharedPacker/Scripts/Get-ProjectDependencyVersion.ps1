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
	Get-PkgProjects -SolutionPath $SolutionPath | % {
		$projPath = [IO.Path]::Combine($slnFolder, $_.ProjectPath)
		[xml]$proj = gc $projPath
		$refs = $proj.Project.ItemGroup | ? { $_.PackageReference }
		$refs.PackageReference | ? { $_.Include -eq $Dependency } | % {
			$version = $_.Version
		}
	}
		
	return $version
}

