if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

. $PSScriptRoot\Initialize-TestNugetConfig.ps1

Describe "Export-NuGetSettings" {
	$projFolder = "TestDrive:\proj"
	$projPath = "$projFolder\proj.sqlproj"
	$configPath = "$projFolder\proj.nuget.config"
	md $projFolder
	Context "Content" {
		$expectedSettings = Initialize-TestNugetConfig
		$expectedOptions = $expectedSettings.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName GitExtension
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName GitExtension
		Context "Dependencies exist" {
			Export-NuGetSettings -NugetConfigPath $configPath -Settings $expectedSettings
			It "Exported nuGet config exists" { Test-Path $configPath | should be $true }
			$importedSettings = Import-NuGetSettings -NugetConfigPath $configPath
			$importedOptions = $importedSettings.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
			It "Options count" { $importedOptions.Length | Should Be $expectedOptions.Length }
			$expectedOptions | % {
				$field = $_
				It "$field content is as expected" {
					iex "`$importedSettings.nugetOptions.$field" |
					should be (iex "`$expectedSettings.nugetOptions.$field") 
				}
			}
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
			$importedOptions = $importedSettings.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
			It "Options count" { $importedOptions.Length | Should Be $expectedOptions.Length }
			$expectedOptions | % {
				$field = $_
				It "$field content is as expected" {
					iex "`$importedSettings.nugetOptions.$field" |
					should be (iex "`$expectedSettings.nugetOptions.$field") 
				}
			}
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