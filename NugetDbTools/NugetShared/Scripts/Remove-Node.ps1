function Remove-Node ($parentNode, $id){
	$childNode = $parentNode.SelectSingleNode($id)
	$parentNode.RemoveChild($childNode) | Out-Null
}