function Set-NodeText ($parentNode, $id, [String]$text){
		[xml.XmlNode]$childNode | Out-Null
		$parentNode.SelectSingleNode($id) |
			Where-Object { $_ } |
			ForEach-Object {
				$childNode = $_
			}
		if (-not $childNode) {
			$newNode = Add-Node -parentNode $parentNode -id $id
			$newNode.InnerText = $text
		}
		else
		{
			$childNode.InnerText = $text
		}
}