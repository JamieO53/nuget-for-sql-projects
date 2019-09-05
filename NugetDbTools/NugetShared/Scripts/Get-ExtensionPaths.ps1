function Get-ExtensionPaths {
	$extensions = @{}
	Get-ToolsConfiguration | % {
		$tools = $_
		$tools.extensions.extension | % {
			$extensions[$_.name] = "$PSScriptRoot\$($_.path)"
		}
	}
	return $extensions
}