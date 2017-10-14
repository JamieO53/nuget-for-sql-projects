$ProjectName = 'NuGetShared'
$SolutionDir = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
$ProjectDir = "$SolutionDir\$ProjectName"
$Dependencies = @()
$Dependents = @('NugetDbPacker', 'MigrateFromCI')

"'$SolutionDir\PowerShell\PSModuleBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
pushd $SolutionDir
.\PowerShell\PSModuleBuilder\PSModuleBuilder.ps1 -project $ProjectName -path "$SolutionDir" -outputPath "$ProjectDir\bin\Debug"
popd
copy "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$Dependencies | % {
	copy "$SolutionDir\$_\bin\Debug\$_\*" "$ProjectDir\bin\Debug\$ProjectName"
}
$Dependents | % {
	copy "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
}
