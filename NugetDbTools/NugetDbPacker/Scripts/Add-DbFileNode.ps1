function Add-DbFileNode ($parentNode) {
	$files = @"
<files>
  <file src="content\Databases\**" target="Databases" />
</files>
"@
	[xml]$child = $files
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.FirstChild, $true))
}