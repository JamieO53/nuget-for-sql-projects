& '.\PowershellBuilder\Build.ps1'
& '.\NugetShared\Build.ps1'
& '.\NugetSharedPacker\Build.ps1'
& '.\NugetDbPacker\Build.ps1'
& '.\NugetProjectPacker\Build.ps1'
& '.\DbSolutionBuilder\Build.ps1'
& '.\TestUtils\Build.ps1'
& '.\Extensions\GitExtension\Build.ps1'
& '.\Extensions\VSTSExtension\Build.ps1'

copy .\PackageTools\* ..\Template.DB\PackageTools