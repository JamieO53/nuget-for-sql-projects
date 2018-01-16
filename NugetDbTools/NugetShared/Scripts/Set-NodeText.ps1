function Set-NodeText ($parentNode, $id, [String]$text){
		[xml.XmlNode]$childNode | Out-Null
		$parentNode.SelectSingleNode($id) |
			where { $_ } |
			foreach {
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