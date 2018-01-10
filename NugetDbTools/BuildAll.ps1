& '.\PowershellBuilder\Build.ps1'
& '.\NugetShared\Build.ps1'
& '.\NugetSharedPacker\Build.ps1'
& '.\NugetDbPacker\Build.ps1'
& '.\NugetProjectPacker\Build.ps1'
& '.\DbSolutionBuilder\Build.ps1'
& '.\TestUtils\Build.ps1'

copy .\PackageTools\* ..\Template.DB\PackageTools