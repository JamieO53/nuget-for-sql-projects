if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1" -Global -DisableNameChecking
if (-not (Get-Module TestUtils)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1" -Global -DisableNameChecking
}

Describe Initialize-NuGetSpec {
	BeforeAll {
		$projFolder = 'TestDrive:\proj'
		$nugetFolder = "$projFolder\NuGet"
		$nugetSpecPath = "$nugetFolder\Package.nuspec"
		$nugetSettings = Initialize-TestNugetConfig -Content 'Database' -NugetContent 'content/Databases/*'
	}
	Context "Nuget spec exists" {
		mkdir $projFolder
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings

		It "NuGet spec file should exist" { (Test-Path $nugetSpecPath) | Should Be $true }
		Remove-Item $projFolder -Recurse -Force
	}
	Context "Drop unused Nuget spec settings" {
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		[xml]$spec = Get-Content $nugetSpecPath
		$metadata = $spec.package.metadata
		Context "Settings removed" {
			$metadata.ChildNodes | Where-Object { $_.Name -ne 'dependencies' } | Where-Object { $_.Name -ne 'contentFiles' } | ForEach-Object {
				$name = $_.Name
				it "$name must be a setting" { $name | Should BeIn $nugetSettings.nugetSettings.Keys }
			}
		}
	}
	Context "Nuget spec settings" {
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- `"$projFolder\*`"" } -ModuleName GitExtension
		mock Invoke-Expression { return '1.0' } -ParameterFilter { $Command -eq 'git describe --tags' } -ModuleName GitExtension
		mkdir $projFolder
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetSpec -Path $nugetFolder -setting $nugetSettings
		Copy-Item $nugetSpecPath "$PSScriptRoot\..\bin\Debug\TestOut.txt"
		[xml]$spec = Get-Content $nugetSpecPath
		$metadata = $spec.package.metadata
		Context "Settings initialized" {
			$nugetSettings.nugetSettings.Keys | ForEach-Object {
				$key = $_
				$value = $nugetSettings.nugetSettings[$key]
				Context "$key value" {
					[xml.xmlnode[]]$node = $metadata.SelectNodes($key)
					It "Should be in the metadata" { $node.Count | Should Be 1 }
					It "should be" { $node.InnerText | Should Be $value }
				}
			}
		}
		Context "Dependencies initialized" {
			$nugetSettings.nugetDependencies.Keys | ForEach-Object {
				$dep = $_
				$ver = $nugetSettings.nugetDependencies[$dep]
				Context "$dep dependency" {
					$nodeVer = $metadata.dependencies.dependency | Where-Object { $_.id -eq $dep}
					It "should be in the metadata dependencies" { $nodeVer | Should Not BeNullOrEmpty }
					It "should be version" { $nodeVer.Version | Should Be $ver }
				}
			}
		}
		Context "Content Files initialized" {
			$nugetSettings.nugetContents.Keys | ForEach-Object {
				$files = $_
				$buildAction = 'none'
				$copyToOutput = 'true'
				Context "$files content files" {
					$nodeFiles = $metadata.contentFiles.files | Where-Object { $_.include -eq $files}
					It "should be in the metadata contentFiles" { $nodeFiles | Should Not BeNullOrEmpty }
					It "should be buildAction" { $nodeFiles.buildAction | Should Be $buildAction }
					It "should be copyToOutput" { $nodeFiles.copyToOutput | Should Be $copyToOutput }
				}
			}
		}
		Remove-Item $projFolder -Recurse -Force
	}
}