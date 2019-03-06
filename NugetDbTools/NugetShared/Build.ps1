$cfg = Import-PowerShellDataFile "$(Split-Path -Path $MyInvocation.MyCommand.Path)\BuildConfig.psd1"

$ProjectName = $cfg.ProjectName
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$ProjectDir = "$SolutionDir\$ProjectName"

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
pushd $SolutionDir
iex "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
popd
copy "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$cfgPath = @{}
$cfg.Dependencies | % {
	$cfgPath.Add($_, "$SolutionDir\$_\bin\Debug\$_\*")
}
$cfg.Extensions | % {
	$cfgPath.Add($_, "$SolutionDir\NuGetSharedPacker\Extensions\$_\bin\Debug\$_\*")
}

$cfgPath.Keys | % {
	$name = $_
	$path = $cfgPath[$name]
	if (Test-Path $path) {
		copy $path "$ProjectDir\bin\Debug\$ProjectName"
	}
}
$cfg.Dependents | % {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		copy "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
	}
}
