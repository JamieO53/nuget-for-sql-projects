if (Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking

Describe "Get-NuGetCachePaths" {
	Context "Exists" {
		It "Can Run" {
			Test-Path function:Get-NuGetCachePaths | should be $true
		}
	}
	Context "Valid paths" {
		Get-NuGetCachePaths | ForEach-Object {
			$source = $_
			It "$source exists" {
				nuget list -Source "$source" | should -Not -BeNullOrEmpty
			}
		}
	}
	Context "Contains NuGet packages" {
		Get-NuGetCachePaths | ForEach-Object {
			$source = $_
			It "$source contains nuget" {
				nuget list -Source "$source" | Where-Object { $_ -like 'nuget*' } | should -Not -BeNullOrEmpty
			}
		}
	}
}