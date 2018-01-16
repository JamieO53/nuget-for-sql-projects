function Add-Node ($parentNode, $id) {
	[xml]$node = "<$id/>"
	$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($node.FirstChild, $true))
	$childNode
}