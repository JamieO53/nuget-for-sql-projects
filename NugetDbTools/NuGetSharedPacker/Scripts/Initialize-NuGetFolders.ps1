function Initialize-NuGetFolders
{
<#.Synopsis
	Creates the NuGet package folders
.DESCRIPTION
	Create the Nuget root folder and sub-folders
.EXAMPLE
	Initialize-NuGetFolders -Path C:\VSTS\EcsShared\SupportRoles\NuGet
#>
    [CmdletBinding()]
	param (
		# The location of the NuGet folders
		[string]$Path
	)
	Remove-NugetFolder -Path $Path
    mkdir "$Path" | Out-Null
    mkdir "$Path\tools" | Out-Null
    mkdir "$Path\lib" | Out-Null
    mkdir "$Path\content" | Out-Null
    mkdir "$Path\content\Databases" | Out-Null
    mkdir "$Path\build" | Out-Null
}