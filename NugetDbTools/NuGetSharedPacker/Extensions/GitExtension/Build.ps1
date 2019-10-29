$ProjectName = 'GitExtension'
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..\..\..").Path
$ProjectDir = "$SolutionDir\NuGetSharedPacker\Extensions\$ProjectName"
$Dependencies = @('NuGetShared')
$Dependents = @('NuGetSharedPacker', 'NugetDbPacker', 'DbSolutionBuilder', 'NuGetProjectPacker')

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir\NuGetSharedPacker\Extensions -outputPath $ProjectDir\bin\Debug"
Push-Location $SolutionDir
if (-not (Test-Path $ProjectDir\bin\Debug\$ProjectName)) {mkdir $ProjectDir\bin\Debug\$ProjectName | Out-Null}
Invoke-Expression "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir\NuGetSharedPacker\Extensions -outputPath $ProjectDir\bin\Debug"
Pop-Location
Copy-Item "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$Dependencies | ForEach-Object {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		Copy-Item "$SolutionDir\$_\bin\Debug\$_\*" "$ProjectDir\bin\Debug\$ProjectName"
	}
}
$Dependents | ForEach-Object {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		Copy-Item "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
	}
}
