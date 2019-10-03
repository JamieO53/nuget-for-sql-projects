function Save-CSharpProject {
<#.Synopsis
	Saves the project data to file.
.DESCRIPTION
	Saves the project data to file.
.EXAMPLE
	Save-CSharpProject -Project $proj -Path .\BackOfficeAuditPkg\BackOfficeAuditPkg.csproj
#>
    [CmdletBinding()]
    param
    (
 		# The project data
		[xml]$Project,
        # The path of the project file
		[string]$Path
	)
	Out-FormattedXml -Xml $Project -FilePath $Path
	$text = Get-Content $Path | Where-Object { $_ -notlike '<`?*`?>'}
	$text | Out-File $Path -Encoding utf8
}