function Add-DictionaryNode ($parentNode, $key, $value) {
	$xml = @"
<nodes>
  <add key="$key" value="$value" />
</nodes>
"@
	[xml]$child = $xml
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.nodes.FirstChild, $true))
}