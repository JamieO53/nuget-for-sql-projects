function Remove-NugetFolder {
    [CmdletBinding()]
	param (
		# The location of the NuGet folders
		[string]$Path
	)
	if (Test-Path $Path) {
		Remove-Item -Path "$Path\*" -Recurse -Force
		Remove-Item -Path $Path -Recurse
	}
}