$cfg = Import-PowerShellDataFile "$(Split-Path -Path $MyInvocation.MyCommand.Path)\BuildConfig.psd1"

$ProjectName = $cfg.ProjectName
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$ProjectDir = "$SolutionDir\$ProjectName"

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
Push-Location $SolutionDir
Invoke-Expression "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
Pop-Location

Copy-Item "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$cfgPath = @{}
$cfg.Dependencies | ForEach-Object {
	$cfgPath.Add($_, "$SolutionDir\$_\bin\Debug\$_\*")
}
$cfg.Extensions | ForEach-Object {
	$cfgPath.Add($_, "$SolutionDir\NuGetSharedPacker\Extensions\$_\bin\Debug\$_\*")
}

$cfgPath.Keys | ForEach-Object {
	$name = $_
	$path = $cfgPath[$name]
	if (Test-Path $path) {
		Copy-Item $path "$ProjectDir\bin\Debug\$ProjectName"
	}
}
$cfg.Dependents | ForEach-Object {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		Copy-Item "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
	}
}
