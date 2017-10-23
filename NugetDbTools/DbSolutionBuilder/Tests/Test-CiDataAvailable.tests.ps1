if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

$saveDevBase = Get-Item $env:DevBase
$env:DevBase = 'TestDrive:\Dev'

Describe "Test-CiDataAvailable" {
	$solutionName = 'TestSolution'
	Context "Dependencies.xml" {
		mkdir "$env:DevBase\$solutionName\trunk\Runtime.annexures"
		mock Write-Host -ModuleName DbSolutionBuilder # block output
		mock Write-Host -ParameterFilter { $Object -eq "Unable to find CI information for TestSolution" } -ModuleName DbSolutionBuilder
		It "Does not exist" { Test-CiDataAvailable $solutionName | should be $false }
		Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "Unable to find CI information for TestSolution" } -ModuleName DbSolutionBuilder -Times 1 -Exactly
		
		'Dependencies' | sc "$env:DevBase\$solutionName\trunk\Runtime.annexures\Dependencies.xml"
		It "Was not called" {
			Test-CiDataAvailable $solutionName | Out-Null |
			Assert-MockCalled Write-Host -ParameterFilter { $Object -eq "Unable to find CI information for TestSolution" } -ModuleName DbSolutionBuilder -Times 1 -Exactly
		}
		rmdir "$env:DevBase\$solutionName*" -Recurse
	}
	
	Context "$solutionName-Dependencies" {
		mkdir "$env:DevBase\$solutionName\trunk\Runtime.annexures"
		mkdir "$env:DevBase\$solutionName\trunk\Runtime"
		'Dependencies' | sc "$env:DevBase\$solutionName\trunk\Runtime.annexures\Dependencies.xml"
		mock Write-Host -ModuleName DbSolutionBuilder # block output
		mock Write-Host { } -ParameterFilter { $Object -eq 'Insufficient information available to determine inherited dependencies' } -ModuleName DbSolutionBuilder
		It "Does not exist" { Test-CiDataAvailable $solutionName | should be $false }

		"$solutionName-Dependencies.xml" | sc "$env:DevBase\$solutionName\trunk\Runtime\$solutionName-Dependencies.xml"
		Test-CiDataAvailable $solutionName | Out-Null
		Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'Insufficient information available to determine inherited dependencies' } -ModuleName DbSolutionBuilder -Times 1 -Exactly
		rmdir "$env:DevBase\$solutionName*" -Recurse
	}
	
	Context "$solutionName-Deploy" {
		mkdir "$env:DevBase\$solutionName\trunk\Runtime.annexures"
		mkdir "$env:DevBase\$solutionName\trunk\Runtime"
		'Dependencies' | sc "$env:DevBase\$solutionName\trunk\Runtime.annexures\Dependencies.xml"
		"$solutionName-Dependencies.xml" | sc "$env:DevBase\$solutionName\trunk\Runtime\$solutionName-Dependencies.xml"
		mock Write-Host -ModuleName DbSolutionBuilder # block output
		mock Write-Host { } -ParameterFilter { $Object -eq 'Insufficient information available to determine the SQLCMD variables' } -ModuleName DbSolutionBuilder
		It "Does not exist" { Test-CiDataAvailable $solutionName | should be $false }

		"$solutionName-Deploy.xml" | sc "$env:DevBase\$solutionName\trunk\Runtime\$solutionName-Deploy.xml"
		Test-CiDataAvailable $solutionName | Out-Null
		Assert-MockCalled Write-Host -ParameterFilter { $Object -eq 'Insufficient information available to determine the SQLCMD variables' } -ModuleName DbSolutionBuilder -Times 1 -Exactly
		rmdir "$env:DevBase\$solutionName*" -Recurse
	}
}

$env:DevBase = $saveDevBase
