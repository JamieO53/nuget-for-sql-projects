Function Format-XmlIndent
{
    # https://gist.github.com/PrateekKumarSingh/96032bd63edb3100c2dda5d64847a48e#file-indentxml-ps1
	[Cmdletbinding()]
    param
    (
        [xml]$Content,
        [int]$Indent
    )

	$StringWriter = New-Object System.IO.StringWriter 
	$Settings = New-Object System.XMl.XmlWriterSettings
	$Settings.Indent = $true
	$Settings.IndentChars = ' ' * $Indent
	$Settings.Encoding = [System.Text.Encoding]::UTF8
    
	$XmlWriter = [System.XMl.XmlWriter]::Create($StringWriter, $Settings)

    $Content.WriteContentTo($XmlWriter) 
    $XmlWriter.Flush();$StringWriter.Flush() 
    $StringWriter.ToString().Replace('<?xml version="1.0" encoding="utf-16"?>','<?xml version="1.0" encoding="utf-8"?>')
}