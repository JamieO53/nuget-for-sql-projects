if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

if (-not (Get-Module TestUtils)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1"
}

Describe "Import-NuGetSettings" {
	$slnFolder = "TestDrive:\sln"
	$slnPath = "$snlFolder\sln.sln"
	$projFolder = "$slnFolder\proj"
	$configPath = "$projFolder\proj.nuget.config"
	$expectedSettings = Initialize-TestNugetConfig -Content 'Database' -NugetContent 'content/Databases/*'
	$expectedOptions = $expectedSettings.nugetOptions | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % { $_.Name }
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
		<add key="owners" value="Dummy Company"/>
		<add key="projectUrl" value="https://dummy.visualstudio.com/Sandbox"/>
		<add key="description" value="This package is for testing NuGet creation functionality"/>
		<add key="releaseNotes" value="Some stuff to say about the release"/>
		<add key="copyright" value="Copyright 2018"/>
	</nugetSettings>
	<nugetDependencies>
		<add key="EcsShared.SharedBase" value="[1.0)"/>
		<add key="EcsShared.SupportRoles" value="[1.0)"/>
	</nugetDependencies>
	<nugetContents>
		<add key="content/Databases/*" value="buildAction=&quot;none&quot; copyToOutput=&quot;true&quot;" />
	</nugetContents>
</configuration>
'@
	md $projFolder
	$config | sc $configPath -Encoding UTF8

	Context "Exists" {
		It "Runs" { Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $slnPath | should not BeNullOrEmpty }
	}
	Context "Content" {
		mock Test-Path { return $true } -ParameterFilter { $Path -eq 'TestDrive:\.git' } -ModuleName NuGetShared
		mock Invoke-Expression { return 1..123 } -ParameterFilter { $Command -eq "git rev-list HEAD -- `"$projFolder\*`"" } -ModuleName GitExtension
		mock Invoke-Expression { return '* master' } -ParameterFilter { $Command -eq 'git branch' } -ModuleName GitExtension
		$content = Import-NuGetSettings -NugetConfigPath $configPath -SolutionPath $slnPath
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
		It "Content count" { $content.nugetContents.Count | should be $expectedSettings.nugetContents.Count }
		$content.nugetContents.Keys | % {
			It "Content file $_" { $content.nugetContents[$_] | should be $expectedSettings.nugetContents[$_] }
		}
	}
}