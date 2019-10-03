$ProjectName = 'TestUtils'
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$ProjectDir = "$SolutionDir\$ProjectName"
$Dependencies = @()
$Dependents = @()

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
Push-Location $SolutionDir
Invoke-Expression "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
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
