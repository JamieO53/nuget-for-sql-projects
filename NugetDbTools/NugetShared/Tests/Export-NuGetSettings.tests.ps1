if ( Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1"

. .\Initialize-TestNugetConfig.ps1

Describe "Export-NuGetSettings" {
	$projFolder = "TestDrive:\proj"
	$projPath = "$projFolder\proj.sqlproj"
	$configPath = "$projFolder\proj.nuget.config"
	md $projFolder
	Context "Content" {
		$expectedSettings = Initialize-TestNugetConfig
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NugetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName NugetShared
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName NugetShared
		Context "Dependencies exist" {
			Export-NuGetSettings -NugetConfigPath $configPath -Settings $expectedSettings
			It "Exported nuGet config exists" { Test-Path $configPath | should be $true }
			$importedSettings = Import-NuGetSettings -NugetConfigPath $configPath
			It "Major version" { $importedSettings.nugetOptions.MajorVersion | should be $expectedSettings.nugetOptions.MajorVersion}
			It "Minor version" { $importedSettings.nugetOptions.MinorVersion | should be $expectedSettings.nugetOptions.MinorVersion}
			It "Settings count" { $importedSettings.nugetSettings.Count | Should Be $expectedSettings.nugetSettings.Count }
			$importedSettings.nugetSettings.Keys | % {
				It "$_ setting is as expected" { $importedSettings.nugetSettings[$_] | should be $expectedSettings.nugetSettings[$_] }
			}
			It "Dependencies count" { $importedSettings.nugetDependencies.Count | Should Be $expectedSettings.nugetDependencies.Count }
			$importedSettings.nugetDependencies.Keys | % {
				It "$_ dependency is as expected" { $importedSettings.nugetDependencies[$_] | should be $expectedSettings.nugetDependencies[$_] }
			}
		}
		Context "Dependencies do not exist" {
			$expectedSettings = Initialize-TestNugetConfig -NoDependencies
			Export-NuGetSettings -NugetConfigPath $configPath -Settings $expectedSettings
			It "Exported nuGet config exists" { Test-Path $configPath | should be $true }
			$importedSettings = Import-NuGetSettings -NugetConfigPath $configPath
			It "Major version" { $importedSettings.nugetOptions.MajorVersion | should be $expectedSettings.nugetOptions.MajorVersion}
			It "Minor version" { $importedSettings.nugetOptions.MinorVersion | should be $expectedSettings.nugetOptions.MinorVersion}
			It "Settings count" { $importedSettings.nugetSettings.Count | Should Be $expectedSettings.nugetSettings.Count }
			$importedSettings.nugetSettings.Keys | % {
				It "$_ setting is as expected" { $importedSettings.nugetSettings[$_] | should be $expectedSettings.nugetSettings[$_] }
			}
			It "Dependencies count" { $importedSettings.nugetDependencies.Count | Should Be $expectedSettings.nugetDependencies.Count }
			$importedSettings.nugetDependencies.Keys | % {
				It "$_ dependency is as expected" { $importedSettings.nugetDependencies[$_] | should be $expectedSettings.nugetDependencies[$_] }
			}
		}
	}
}