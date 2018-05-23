if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}

$global:testing = $true
$location = "TestDrive:\Solutions"
$name = 'TestSolution'
function New-DummyDacpac {
	param (
		[string]$DbName
	)
	if (-not (Test-Path "$location\$name\PackageContent\$DbName\Databases")) {
		mkdir -Path "$location\$name\PackageContent\$DbName\Databases"
	}
	$DbName | Set-Content -Path "$location\$name\PackageContent\$DbName\Databases\$DbName.dacpac"
}
$dbNames = @('db1', 'db2')
$databases = ''
$dbNames | % {
	$databases += @"

		<database dbName=`"$_`"/>
"@
}
$deps = @{dep1='1.0.123'; dep2='1.0.234'}
$dependencies = ''
$deps.Keys | % {
	$dependencies += @"

	<dependency id=`"$_`"/>
"@
}
Describe "New-DbSolution" {
	$location = "$testDrive\Solutions"
	[xml]$params = @"
<dbSolution>
	<parameters>
		<location>$location</location>
		<name>$name</name>
	</parameters>
	<databases>$databases
	</databases>
	<dependencies>$dependencies
	</dependencies>
</dbSolution>
"@
	mkdir 'TestDrive:\Configuration'
	copy "$env:APPDATA\JamieO53\NugetDbTools\NugetDbTools.config" 'TestDrive:\Configuration\NugetDbTools.config'
	$deps.Keys | % {
		New-DummyDacpac -DbName $_
	}
	Context "Solution folder" {
		Mock -CommandName Invoke-Expression -ParameterFilter { $PSBoundParameters.Command -eq "nuget list dep1 -Source $(Get-NuGetLocalSource)"} -MockWith { 'dep1 1.0.123' } -ModuleName NuGetShared
		Mock -CommandName Invoke-Expression -ParameterFilter { $PSBoundParameters.Command -eq "nuget list dep2 -Source $(Get-NuGetLocalSource)"} -MockWith { 'dep2 1.0.234' } -ModuleName NuGetShared
		$temp = New-DbSolution -Parameters $params
		It "$location\$name folder exists" {
			Test-Path "$location\$name" | should be $true
		}
		It "$($name) solution exists" {
			Test-Path "$location\$name\$($name).sln" | should be $true
		}
		It "$location\$name\$($name)Pkg folder exists" {
			Test-Path "$location\$name\$($name)Pkg" | should be $true
		}
		It "$($name)Pkg project exists" {
			Test-Path "$location\$name\$($name)Pkg\$($name)Pkg.csproj" | should be $true
		}
		$cs = Get-CSharpProjects -SolutionPath "$location\$name\$name.sln"
		It "Only one C# project is in the solution" {
			$cs.Count | should benullorempty
		}
		It "$($name)Pkg project is in the solution" {
			$cs.Project | should be "$($name)Pkg"
		}
		It "$($name)Pkg project path is in the solution" {
			$cs.ProjectPath | should be "$($name)Pkg\$($name)Pkg.csproj"
		}
		It "$($name)Pkg project GUID should be changed" {
			$cs.ProjectGuid | should not be '1D72F9F5-2ED0-4157-9EF8-903203AA428C'
		}
		[xml]$prj = gc "$location\$name\$($cs.ProjectPath)"
		It "Project header" {
			$prj.xml | should be $null
		}
		Context "Dependencies" {
			It "The specified properties were added" {
				($prj.Project.ItemGroup.PackageReference).Count | should be 4
			}
			Context "Versions" {
				$originalVersions = @{
					NuGetShared = '0.1.1';
					NuGetSharedPacker = '0.1.1';
					NuGetDbPacker = '0.1.1'
				}
				$prj.Project.ItemGroup.PackageReference | % {
					if ($deps[$_.Include]) {
						It "$($_.Include) version" {
							$_.Version | should be $deps[$_.Include]
						}
					} else {
						It "$($_.Include) version" {
							$_.Version | should not be $originalVersions[$_.Include]
						}
					}
				}
			}
		}
		$sql = Get-SqlProjects -SolutionPath "$location\$name\$name.sln"
		It "Two SQL projects are in the solution" {
			$sql.Count | should be 2
		}
		$sql | % {
			$projectName = $_.Project
			$projectPath = "$location\$name\$($_.ProjectPath)"
			$projectFolder = "$location\$name\$ProjectName"
			$projectNugetConfigPath = "$projectFolder\$projectName.nuget.config"
			$projText = gc $projectPath | Out-String
			$nugetDbToolsVersion = Get-NuGetPackageVersion -PackageName NuGetDbPacker
			Context "SQL project $projectName in solution" {
				It "$($_.Project) project exists" {
					Test-Path $projectPath | should be $true
				}
				It "$($_.Project) NuGet configuration exists" {
					Test-Path $projectNugetConfigPath | should be $true
				}
				It "Should start witn $name." {
					$_.Project | should belike "$name.*"
				}
				It "Should be a test DB" {
					$_.Project.Replace("$name.", '') | should bein $dbNames
				}
				It "Project path" {
					$_.ProjectPath | should be "$projectName\$projectName.sqlproj"
				}
				It "$($_.Project) project GUID should be changed" {
					$sql.ProjectGuid | should not be '96EEF452-0302-4B98-BDBC-D36A24C21EA8'
				}
			}
			Context "$projectName.nuget.config content" {
				[xml]$nconfig = gc $projectNugetConfigPath
				$nugetDbToolsRef = $nconfig.configuration.nugetDependencies.add | ? { $_.key -eq 'NuGetDbPacker' }
				It "NuGetDbTools version" {
					$nugetDbToolsRef.value | should be $nugetDbToolsVersion
				}
				$deps.Keys | % {
					$dep = $_
					$ref = $nconfig.configuration.nugetDependencies.add | ? { $_.key -eq $dep }
					It "$dep dependency should exist" {
						$ref | should not benullorempty
					}
					It "$dep dependency version" {
						$ref.value | should be $deps[$dep]
					}
				
				}
			}
			Context "$projectName project file" {
				[xml]$proj = $projText
				$includes = ($proj.Project.ItemGroup.None | % { $_.Include })
				It "$($_.Project) NuGet configuration referenced from project file" {
					"$projectName.nuget.config" | should bein $includes
				}
				It "Template.DbProject NuGet configuration should not be referenced from project file" {
					"Template.DbProject.nuget.config" | should not bein $includes
				}
				$refs = $proj.Project.ItemGroup.ArtifactReference
				$deps.Keys + 'NugetDbPackerDb.Root' | % {
					$dep = $_
					Context "$dep database reference" {
						$ref = $refs | ? { $_.Include -eq "..\Databases\$dep.dacpac"}
						It "Exists" {
							$ref | should not be $null
						}
						It "HintPath" {
							$ref.HintPath | should be "..\Databases\$dep.dacpac"
						}
						It "SuppressMissingDependenciesErrors" {
							$ref.SuppressMissingDependenciesErrors | should be 'False'
						}
					}
				}
			}
		}
		Context "Package Tools" {
			It "PackageTools folder exists in solution" {
				Test-Path "$location\$name\PackageTools" | should be $true
			}
			'Bootstrap.ps1','Bootstrap.cmd', 'Get-PackageContent.ps1', 'GetPackageContent.cmd', 'Publish-DbProjects.ps1', 'PublishDbProjects.cmd' | % {
				It "PackageTools folder contains $_" {
					Test-Path "$location\$name\PackageTools\$_" | should be $true
				}
			}
		}
	}
}
$global:testing = $false