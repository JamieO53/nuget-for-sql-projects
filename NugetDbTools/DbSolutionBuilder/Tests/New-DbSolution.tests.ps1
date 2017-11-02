if ( Get-Module DbSolutionBuilder) {
	Remove-Module DbSolutionBuilder
}
Import-Module "$PSScriptRoot\..\bin\Debug\DbSolutionBuilder\DbSolutionBuilder.psm1"

$location = 'TestDrive:\Solutions'
$name = 'TestSolution'
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
Describe "New-DbSolution" {
	Context "Solution folder" {
		Mock -CommandName 'Invoke-Expression' -ParameterFilter { $PSBoundParameters.Command -eq "nuget list dep1 -Source $(Get-NuGetLocalSource)"} -MockWith { 'dep1 1.0.123' } -ModuleName NugetShared
		Mock -CommandName 'Invoke-Expression' -ParameterFilter { $PSBoundParameters.Command -eq "nuget list dep2 -Source $(Get-NuGetLocalSource)"} -MockWith { 'dep2 1.0.234' } -ModuleName NugetShared
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
		Context "Dependencies" {
			It "The specified properties were added" {
				($prj.Project.ItemGroup.PackageReference).Count | should be 3
			}
			Context "Versions" {
				$originalVersions = @{
					NuGetShared = '0.1.1';
					NuGetDbPacker = '0.1.21'
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
			Context "SQL project $($_.Project) in solution" {
				It "$($_.Project) project exists" {
					Test-Path "$location\$name\$($_.ProjectPath)" | should be $true
				}
				It "Should start witn $name." {
					$_.Project | should belike "$name.*"
				}
				It "Should be a test DB" {
					$_.Project.Replace("$name.", '') | should bein $dbNames
				}
				It "Project path" {
					$_.ProjectPath | should be "$($_.Project)\$($_.Project).sqlproj"
				}
				It "$($_.Project) project GUID should be changed" {
					$sql.ProjectGuid | should not be '96EEF452-0302-4B98-BDBC-D36A24C21EA8'
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