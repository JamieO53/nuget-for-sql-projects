if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

. $PSScriptRoot\Initialize-TestNugetConfig.ps1

Describe "Import-NuGetSettings" {
	$projFolder = "TestDrive:\proj"
	$configPath = "$projFolder\proj.nuget.config"
	$expectedSettings = Initialize-TestNugetConfig
	$expectedOptions = $expectedSettings | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
	$config = @'
<?xml version="1.0"?>
<configuration>
	<nugetOptions>
		<add key="majorVersion" value="1"/>
		<add key="minorVersion" value="0"/>
		<add key="contentFolders" value="Database"/>
	</nugetOptions>
	<nugetSettings>
		<add key="id" value="TestPackage"/>
		<add key="authors" value="joglethorpe"/>
		<add key="owners" value="Jamie Oglethorpe"/>
		<add key="projectUrl" value="https://epsdev.visualstudio.com/Sandbox"/>
		<add key="description" value="This package is for testing NuGet creation functionality"/>
		<add key="releaseNotes" value="Some stuff to say about the release"/>
		<add key="copyright" value="Copyright 2017"/>
	</nugetSettings>
	<nugetDependencies>
		<add key="EcsShared.SharedBase" value="[1.0)"/>
		<add key="EcsShared.SupportRoles" value="[1.0)"/>
	</nugetDependencies>
</configuration>
'@
	md $projFolder
	$config | sc $configPath -Encoding UTF8

	Context "Exists" {
		It "Runs" { Import-NuGetSettings -NugetConfigPath $configPath | should not BeNullOrEmpty }
	}
	Context "Content" {
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- $projFolder" } -ModuleName GitExtension
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName GitExtension
		$content = Import-NuGetSettings -NugetConfigPath $configPath
		$options = $content.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
		It "Options count" { $options.Length | Should Be $expectedOptions.Length }
		$expectedOptions | % {
			$field = $_
			It "$field content is as expected" {
				iex "`$content.nugetOptions.$field" |
				should be (iex "`$expectedSettings.nugetOptions.$field") 
			}
		}
		It "Settings count" { $content.nugetSettings.Count | Should Be $expectedSettings.nugetSettings.Count }
		$content.nugetSettings.Keys | % {
			It "$_ content is as expected" { $content.nugetSettings[$_] | should be $expectedSettings.nugetSettings[$_] }
		}
		It "Dependencies count" { $content.nugetDependencies.Count | should be $expectedSettings.nugetDependencies.Count }
		$content.nugetDependencies.Keys | % {
			It "Content dependency $_" { $content.nugetDependencies[$_] | should be $expectedSettings.nugetDependencies[$_] }
		}
	}
}