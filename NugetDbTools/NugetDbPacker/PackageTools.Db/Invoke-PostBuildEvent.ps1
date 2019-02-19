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

copy "$tgtFolder\$ProjectName.dacpac" $outputFolder
if ($CopyAssembly) {
	copy "$tgtFolder\$AssemblyName.*" $outputFolder
}
if (Test-Path "$tgtFolder\$ProjectName.publish.xml") {
	copy "$tgtFolder\$ProjectName.publish.xml" $outputFolder
}

if (Test-Path "$outputFolder\unzipped") {
	rmdir $outputFolder\unzipped\* -Recurse -Force
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
Get-Module Microsoft.PowerShell.Archive | ? { $_.Version.ToString() -eq '1.0.1.0'} | % {
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

ls $outputFolder\unzipped\*deploy.sql | % {
	copy $_.FullName "$outputFolder\$ProjectName.dacpac.$($_.Name)"
}

rmdir $outputFolder\unzipped* -Recurse -Force