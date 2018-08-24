$ProjectName = 'NuGetProjectPacker'
$SolutionDir = (Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\..").Path
$ProjectDir = "$SolutionDir\$ProjectName"
$Dependencies = @('NuGetShared','NuGetSharedPacker','Extensions\GitExtension','Extensions\VSTSExtension')
$Dependents = @()

"'$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1' -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
pushd $SolutionDir
iex "$SolutionDir\PowershellBuilder\PSModuleBuilder.ps1 -project $ProjectName -path $SolutionDir -outputPath $ProjectDir\bin\Debug"
popd
copy "$ProjectDir\$ProjectName.psd1" "$ProjectDir\bin\Debug\$ProjectName"
$Dependencies | % {
	$name=(Split-Path $_ -Leaf)
	if (Test-Path "$SolutionDir\$_\bin\Debug\$name") {
		copy "$SolutionDir\$_\bin\Debug\$name\*" "$ProjectDir\bin\Debug\$ProjectName"
	}
}
$Dependents | % {
	if (Test-Path "$SolutionDir\$_\bin\Debug\$_") {
		copy "$ProjectDir\bin\Debug\$ProjectName\*" "$SolutionDir\$_\bin\Debug\$_"
	}
}
