param (
	[string]$ProjectName,
	[string]$ProjectDir,
	[string]$SolutionDir,
	[string]$TargetDir,
	[string]$AssemblyName,
	[switch]$CopyAssembly = $false
)

$slnFolder = $SolutionDir.TrimEnd("\")
$prjFolder = $ProjectDir.TrimEnd("\")
$tgtFolder = $TargetDir.TrimEnd("\")
$outputFolder = "$prjFolder\Databases"

if (-not (Test-Path $outputFolder)) {
	mkdir $outputFolder | Out-Null
}

if (Test-Path "$tgtFolder\master.dacpac") {
	Copy-Item "$tgtFolder\master.dacpac" $outputFolder -Force
}
Copy-Item "$tgtFolder\$ProjectName.dacpac" $outputFolder
if ($CopyAssembly) {
	Copy-Item "$tgtFolder\$AssemblyName.*" $outputFolder
}
if (Test-Path "$tgtFolder\$ProjectName.publish.xml") {
	Copy-Item "$tgtFolder\$ProjectName.publish.xml" $outputFolder
}
if (Test-Path "$tgtFolder\$ProjectName.*.publish.xml") {
	Copy-Item "$tgtFolder\$ProjectName.*.publish.xml" $outputFolder
}

if (Test-Path "$outputFolder\unzipped") {
	Remove-Item $outputFolder\unzipped\* -Recurse -Force
} else {
	mkdir $outputFolder\unzipped | Out-Null
}

$oldVersion = $false
if (-not (Get-Module Microsoft.PowerShell.Archive)) {
	Import-Module Microsoft.PowerShell.Archive
}
if (-not (Get-Module Microsoft.PowerShell.Archive)) {
	Write-Host 'Module Microsoft.PowerShell.Archive must be installed to use this functionality. See https://www.powershellgallery.com/packages/Microsoft.PowerShell.Archive/1.1.0.0'
	Exit 1
}
Get-Module Microsoft.PowerShell.Archive | Where-Object { $_.Version.ToString() -eq '1.0.1.0'} | ForEach-Object {
	if ($_.Version) {
		$oldVersion = $true
	}
}

if ($oldVersion) {
	try {
		Rename-Item $outputFolder\$ProjectName.dacpac $outputFolder\$ProjectName.dacpac.zip
		Expand-Archive -LiteralPath $outputFolder\$ProjectName.dacpac.zip -DestinationPath $outputFolder\unzipped
	} finally {
		Rename-Item $outputFolder\$ProjectName.dacpac.zip $outputFolder\$ProjectName.dacpac
	}
} else {
	Expand-Archive -LiteralPath $outputFolder\$ProjectName.dacpac -DestinationPath $outputFolder\unzipped
}

Get-ChildItem $outputFolder\unzipped\*deploy.sql | ForEach-Object {
	Copy-Item $_.FullName "$outputFolder\$ProjectName.dacpac.$($_.Name)"
}

Remove-Item $outputFolder\unzipped* -Recurse -Force
