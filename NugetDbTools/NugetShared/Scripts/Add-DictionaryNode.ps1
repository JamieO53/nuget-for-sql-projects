function Add-DictionaryNode ($parentNode, $key, $value) {
	$dic = Add-Node -parentNode $parentNode -id 'add'
	$dic.SetAttribute('key', $key)
	$dic.SetAttribute('value', $value)
}