param (
	[string]$ProjectName,
	[string]$ProjectDir,
	[string]$SolutionDir,
	[string]$TargetDir
)

$prjFolder = $ProjectDir.TrimEnd("\")
$outputFolder = "$prjFolder\Databases"

if (Test-Path "$outputFolder\unzipped") {
	rmdir $outputFolder\unzipped* -Recurse -Force
}