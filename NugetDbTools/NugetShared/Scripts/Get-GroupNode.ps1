function Get-GroupNode ($parentNode, $id) {
	$gn = $parentNode.SelectSingleNode($id)
	if ($gn) {
		$gn
	} else {
		Add-Node -parentNode $parentNode -id $id
	}
}