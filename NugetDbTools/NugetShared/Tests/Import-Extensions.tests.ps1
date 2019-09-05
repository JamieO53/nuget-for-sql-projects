Describe "Import-Extensions" {
	$solutionPath = "TestDrive:\solution"
	$packageToolsPath = "$solutionPath\PackageTools"
	$powerShellPath = "$solutionPath\PowerShell"
	$toolConfigPath = "$packageToolsPath\PackageTools.root.config"
	$toolConfigExist = @"
<?xml version=`"1.0`"?>
<tools>
	<extensions>
		<extension name=`"extension1`" path=`"extension1.psm1`" />
		<extension name=`"extension2`" path=`"extension2.psm1`" />
	</extensions>
</tools>
"@
$toolConfigMissing = @"
<?xml version=`"1.0`"?>
<tools>
	<extensions>
		<extension name=`"extension1`" path=`"extension1.psm1`" />
		<extension name=`"extension2`" path=`"extension2.psm1`" />
		<extension name=`"extension3`" path=`"extension3.psm1`" />
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
	ls $PSScriptRoot
	copy "$PSScriptRoot\..\bin\Debug\NugetShared\*" $powerShellPath
	'function Extension1Function {}' | Out-File "$powerShellPath\extension1.psm1"
	'function Extension2Function {}' | Out-File "$powerShellPath\extension2.psm1"
	Import-Module "$powerShellPath\NugetShared.psm1" -Global -DisableNameChecking

	Context "Exists" {
		It "Test for function" {
			Test-Path function:Import-Extensions | should -BeTrue
		}
	}
	Context "Extension installation" {
		Remove-Module extension1,extension2 -ErrorAction SilentlyContinue
		$toolConfigExist | Out-File $toolConfigPath -Encoding utf8
		Import-Extensions
		'extension1','extension2' | % {
			$ext = $_
			It "Extension $ext is installed" {
				Get-Module $ext | should -Not -BeNullOrEmpty
			}
			It "Function $($ext)Function exists" {
				Test-Path "function:$($ext)Function" | should -BeTrue
			}
		}
	}
	Context "Configured extension missing" {
		Remove-Module extension1,extension2 -ErrorAction SilentlyContinue
		$toolConfigMissing | Out-File $toolConfigPath -Encoding utf8
		It "Exception for missing extension" {
			{ Import-Extensions } | should -Throw "Unable to import extension extension3"
		}
	}
}