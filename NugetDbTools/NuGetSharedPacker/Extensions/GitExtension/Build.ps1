$ProjectName = 'GitExtension'
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..\..\..").Path
$ProjectDir = "$SolutionDir\NuGetSharedPacker\Extensions\$ProjectName"
$Dependencies = @('NuGetShared')
$Dependents = @('NuGetSharedPacker', 'NugetDbPacker', 'DbSolutionBuilder', 'NuGetProjectPacker')

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir\NuGetSharedPacker\Extensions -outputPath $ProjectDir\bin\Debug"
pushd $SolutionDir
if (-not (Test-Path $ProjectDir\bin\Debug\$ProjectName)) {mkdir $ProjectDir\bin\Debug\$ProjectName | Out-Null}
iex "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir\NuGetSharedPacker\Extensions -outputPath $ProjectDir\bin\Debug"
popd
copy "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$Dependencies | % {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		copy "$SolutionDir\$_\bin\Debug\$_\*" "$ProjectDir\bin\Debug\$ProjectName"
	}
}
$Dependents | % {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		copy "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
	}
}
