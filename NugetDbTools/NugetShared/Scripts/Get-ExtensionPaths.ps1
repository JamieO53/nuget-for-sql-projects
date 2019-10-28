function Get-ExtensionPaths {
	$extensions = @{}
	Get-ToolsConfiguration | ForEach-Object {
		$tools = $_
		$tools.extensions.extension | ForEach-Object {
			$extensions[$_.name] = "$PSScriptRoot\$($_.path)"
		}
	}
	return $extensions
}