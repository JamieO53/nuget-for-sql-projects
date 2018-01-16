function Add-DbFileNode ($parentNode) {
	$files = Get-GroupNode -parentNode $parentNode -id 'files'
	$file = Add-Node -parentNode $files -id file
	$file.SetAttribute('src', 'content\Databases\**')
	$file.SetAttribute('target', 'Databases')
}