Function Out-FormattedXml {
	param (
		[xml]$Xml,
		[string]$FilePath
	)
	Format-XMLIndent $Xml -Indent 2 | Out-File $FilePath -Encoding utf8
}

