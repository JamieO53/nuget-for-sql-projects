function Set-NodeText ($parentNode, $id, [String]$text){
	[xml.XmlNode]$childNode
	$parentNode.SelectSingleNode($id) |
		where { $_ } |
		foreach {
			$childNode = $_
		}
    if (-not $childNode) {
		[xml]$child = "<$id>$text</$id>"
		$childNode = $parentNode.AppendChild($parentNode.OwnerDocument.ImportNode($child.FirstChild, $true))
	}
	else
	{
		$childNode.InnerText = $text
	}
}