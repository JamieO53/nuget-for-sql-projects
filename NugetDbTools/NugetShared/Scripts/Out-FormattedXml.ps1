Function Out-FormattedXml {
	param (
		[xml]$Xml,
		[string]$FilePath
	)
	[xml]$outXml = $Xml.OuterXml.Replace(' xmlns=""','') # Introduced when adding a node to a VS project file
	Format-XMLIndent $outXml -Indent 2 | Out-File $FilePath -Encoding utf8
}