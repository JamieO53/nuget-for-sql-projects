# if ( Get-Module NugetDbPacker) {
# 	Remove-Module NugetDbPacker
# }
# Import-Module "$PSScriptRoot\..\bin\Debug\NugetDbPacker\NugetDbPacker.psm1"
# Describe "Publish-DbPackage" {
# 	Context "Exists" {
# 		It "Runs" {
#			Publish-DbPackage -ProjectPath C:\VSTS\Backoffice\EcsShared\SupportRoles\EcsShared.SupportRoles.sqlproj
# 		}
# 	}
# }