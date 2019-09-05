& "$PSScriptRoot\PowershellBuilder\Build.ps1"
& "$PSScriptRoot\NugetShared\Build.ps1"
& "$PSScriptRoot\NugetSharedPacker\Extensions\GitExtension\Build.ps1"
& "$PSScriptRoot\NugetSharedPacker\Extensions\VSTSExtension\Build.ps1"
& "$PSScriptRoot\NugetSharedPacker\Build.ps1"
& "$PSScriptRoot\NugetDbPacker\Build.ps1"
& "$PSScriptRoot\NugetProjectPacker\Build.ps1"
& "$PSScriptRoot\DbSolutionBuilder\Build.ps1"
& "$PSScriptRoot\TestUtils\Build.ps1"

copy $PSScriptRoot\PackageTools\* $PSScriptRoot\..\Template.DB\PackageTools