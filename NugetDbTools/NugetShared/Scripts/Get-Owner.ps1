function Get-Owner {
	<#.Synopsis
	Gets the file's owner
	.DESCRIPTION
    Tests if the file can be opened exclusively
	.EXAMPLE
	if ((Get-Owner -Path C:\VSTS\Batch\Batch.sln) -eq 'BUILTIN\Administrators') {...}
	#>
	[CmdletBinding()]
	[OutputType([string])]
    param
    (
        # The file being tested
        [string]$Path
	)
	$acl = Get-Acl -Path $Path
	$sid = $acl.GetOwner([System.Security.Principal.SecurityIdentifier])
	[string]$owner = $sid.Translate([System.Security.Principal.NTAccount]).Value
	$owner
}