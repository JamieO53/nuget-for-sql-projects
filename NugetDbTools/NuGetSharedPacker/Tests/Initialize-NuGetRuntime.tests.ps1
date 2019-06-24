if ( Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
Import-Module "$PSScriptRoot\..\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psm1"

if (-not (Get-Module TestUtils)) {
	Import-Module "$PSScriptRoot\..\..\TestUtils\bin\Debug\TestUtils\TestUtils.psd1"
}

Describe "Initialize-NuGetRuntime" {
	$solutionFolder = 'TestDrive:\sln'
	$solutionPath = "$solutionFolder\sln.sln"
	$projectFolder = "$solutionFolder\proj"
	$projectPath = "$projectFolder\proj.csproj"
	$nugetFolder = "$projectFolder\NuGet"
	$solutionContentFolder = "$solutionFolder\Runtime"
	$solutionContentPath = "$solutionContentFolder\slnContent.txt"
	$solutionOverrideContentPath = "$solutionContentFolder\projContent.txt"
	$solutionContent = 'Solution runtime data'
	$projectContentFolder = "$projectFolder\Runtime"
	$projectContentPath = "$projectContentFolder\projContent.txt"
	$projectContent = 'Project runtime data'
	$nugetRuntimeFolder = "$nugetFolder\content\Runtime"
	$nugetSolutionContentPath = "$nugetRuntimeFolder\slnContent.txt"
	$nugetProjectContentPath = "$nugetRuntimeFolder\projContent.txt"
	Context "Exists" {
		It "Runs" {
			Get-Item function:Initialize-NuGetRuntime | should not be $null
		}
	}
	Context "Runtime in project" {
		mkdir $projectFolder | Out-Null
		mkdir $projectContentFolder
		$projectContent | Out-File $projectContentPath -Encoding utf8
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetRuntime -SolutionPath $solutionPath -ProjectPath $projectPath -Path $nugetFolder
		It "Project runtime in NuGet content" {
			Test-Path $nugetProjectContentPath | should be $true
		}
	}
	Context "Runtime in solution" {
		mkdir $projectFolder | Out-Null
		mkdir $solutionContentFolder
		$solutionContent | Out-File $solutionContentPath -Encoding utf8
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetRuntime -SolutionPath $solutionPath -ProjectPath $projectPath -Path $nugetFolder
		It "Solution runtime in NuGet content" {
			Test-Path $nugetSolutionContentPath | should be $true
		}
	}
	Context "Runtime in project and solution" {
		mkdir $projectFolder | Out-Null
		mkdir $projectContentFolder
		mkdir $solutionContentFolder
		$projectContent | Out-File $projectContentPath -Encoding utf8
		$solutionContent | Out-File $solutionContentPath -Encoding utf8
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetRuntime -SolutionPath $solutionPath -ProjectPath $projectPath -Path $nugetFolder
		It "Project runtime in NuGet content" {
			Test-Path $nugetProjectContentPath | should be $true
		}
		It "Solution runtime in NuGet content" {
			Test-Path $nugetSolutionContentPath | should be $true
		}
	}
	Context "Runtime in project overrides solution" {
		mkdir $projectFolder | Out-Null
		mkdir $projectContentFolder
		mkdir $solutionContentFolder
		$projectContent | Out-File $projectContentPath -Encoding utf8
		$solutionContent | Out-File $solutionOverrideContentPath -Encoding utf8
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetRuntime -SolutionPath $solutionPath -ProjectPath $projectPath -Path $nugetFolder
		It "Project runtime in NuGet content" {
			Test-Path $nugetProjectContentPath | should be $true
		}
		It "Project content overrides solution content" {
			gc $nugetProjectContentPath | should be $projectContent
		}
	}
	Context "Runtime in neither project or solution" {
		mkdir $projectFolder | Out-Null
		Initialize-NuGetFolders -Path $nugetFolder
		Initialize-NuGetRuntime -SolutionPath $solutionPath -ProjectPath $projectPath -Path $nugetFolder
		It "No runtime folder in NuGet content" {
			Test-Path $nugetRuntimeFolder | should be $false
		}
	}
}