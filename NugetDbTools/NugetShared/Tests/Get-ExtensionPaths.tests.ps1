Describe "Get-ExtensionPaths" {
	$solutionPath = "TestDrive:\solution"
	$packageToolsPath = "$solutionPath\PackageTools"
	$powerShellPath = "$solutionPath\PowerShell"
	$toolConfigPath = "$packageToolsPath\PackageTools.root.config"
	$toolConfigExist = @"
<?xml version=`"1.0`"?>
<tools>
	<extensions>
		<extension name=`"extension1`" path=`"extension1.ps1`" />
		<extension name=`"extension2`" path=`"extension2.ps1`" />
	</extensions>
</tools>
"@
	if (Get-Module NugetShared) {
		Remove-Module NugetShared
	}
	if (Test-Path $solutionPath) {
		rmdir "$solutionPath*" -Force -Recurse
	}
	mkdir $powerShellPath | Out-Null
	mkdir $packageToolsPath | Out-Null
	copy "$PSScriptRoot\..\bin\Debug\NugetShared\*" $powerShellPath
	'function Extension1Function {}' | Out-File "$powerShellPath\extension1.ps1"
	'function Extension2Function {}' | Out-File "$powerShellPath\extension2.ps1"
	Import-Module "$powerShellPath\NugetShared.psm1"

	Context "Exists" {
		It "Test for function" {
			Test-Path function:Get-ExtensionPaths | should -BeTrue
		}
	}
	Context "Existing extensions" {
		$toolConfigExist | Out-File $toolConfigPath -Encoding utf8
		$extensions = Get-ExtensionPaths
		$path = "$testDrive\solution\PowerShell"
		'extension1','extension2' | % {
			It "Extension $_ is returned" {
				$extensions[$_] | should be "$path\$_.ps1"
			}
		}
		$extensions.Keys | sort | % {
			It "Extension $_ ($($extensions[$_])) exists" {
				Test-Path $extensions[$_] | should -BeTrue
			}
		}
	}
}