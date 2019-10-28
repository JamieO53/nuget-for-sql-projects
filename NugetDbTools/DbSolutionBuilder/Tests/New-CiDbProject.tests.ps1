Describe "New-CiDbProject" {
#
# Set up test environment and invoke New-CiDbProject.ps1
#
function Install-DevOpsTools {
    $dbTools = 'C:\AzureDevOps\ContinuousIntegration\nuget-for-sql-projects\NugetDbTools'
    if (-not (Get-Module TestUtils)) {
        Import-Module C:\AzureDevOps\ContinuousIntegration\nuget-for-sql-projects\NugetDbTools\TestUtils\bin\Debug\TestUtils\TestUtils.psm1
    }
    mkdir .\PowerShell | Out-Null
    Copy-Item $dbTools\DbSolutionBuilder\bin\Debug\DbSolutionBuilder\* .\PowerShell -Force
    mkdir .\PackageTools | Out-Null
    Copy-Item $dbTools\PackageTools\* .\PackageTools -Force
    Copy-Item $dbTools\NugetDbPacker\PackageTools.Db\* .\PackageTools -Force
    Copy-Item $dbTools\DbSolutionBuilder\PackageTools.Builder.Db\* .\PackageTools -Recurse -Force
    Copy-Item .\PackageTools\DbTemplate.xml . -Force
    Copy-Item .\PackageTools\New-CiDbProject.ps1 . -Force
    $config = @"
<?xml version="1.0"?>
<tools>
    <extensions>
        <extension name=`"GitExtension`" path="`GitExtension.psm1`" />
        <extension name=`"VSTSExtension`" path="`VSTSExtension.psm1`" />
    </extensions>
    <content>
        <contentFolder>Runtime</contentFolder>
    </content>
    <nuget>
        <source>$nuGetSource</source>
        <apiKey>ApiKey</apiKey>
    </nuget>
</tools>
"@
    $config | Out-File .\PackageTools\PackageTools.root.config -Encoding utf8
$params = @"
<dbSolution>
    <parameters>
        <location>$solutionsFolder</location>
        <name>$solutionName</name>
    </parameters>
    <databases>
        <database dbName=`"db1`"/>
        <database dbName=`"db2`"/>
    </databases>
    <dependencies>
        <dependency id=`"dep1`"/>
        <dependency id=`"dep2`"/>
    </dependencies>
</dbSolution>
"@
    $params | Out-File ".\$solutionName.xml" -Encoding UTF8
    if (Get-Module NugetShared* -All) {
        Remove-Module NugetShared* -Force
    }
    Import-Module .\PowerShell\NuGetSharedPacker.psd1
}
function Install-TestReferences {
    if (Test-Path $nuGetSource) {
        Remove-Item "$nuGetSource*" -Force -Recurse
    }
    mkdir $nuGetSource | Out-Null
    New-Dep 'dep1' '1.0.123'
    New-Dep 'dep2' '1.0.234'
	New-Dep 'NuGetDbPacker' '1.0.99'
	New-Template
}
function New-Template {
    $id = 'NuGetDbPacker.DbTemplate'
    $version = '1.0.99'
    $nugetFolder = "$testDrive\DevOpsTools\NuGet\$id"
    $templateFolder = 'C:\AzureDevOps\ContinuousIntegration\nuget-for-sql-projects\Template.DB'
    $nugetSettings = Initialize-TestNugetConfig -NoDependencies
    $nugetSettings.nugetSettings.id = $id
    $nugetSettings.nugetSettings.version = $version
    Initialize-NuGetFolders $nugetFolder
    mkdir $nugetFolder\PackageTools | Out-Null
    Copy-Item $templateFolder\PackageTools\Bootstrap.* $nugetFolder\PackageTools
    mkdir $nugetFolder\Template\Template.DBPkg | Out-Null
    Copy-Item $templateFolder\Template.DBPkg\Template.DBPkg.csproj $nugetFolder\Template\Template.DBPkg
    mkdir $nugetFolder\Template\Template.DBProject | Out-Null
    Copy-Item $templateFolder\Template.DBProject\Template.DBProject.sqlproj $nugetFolder\Template\Template.DBProject
    Copy-Item $templateFolder\Template.DBProject\Template.DBProject.nuget.config $nugetFolder\Template\Template.DBProject
    Copy-Item $templateFolder\Template.DBProject\Template.DBProject.publish.xml $nugetFolder\Template\Template.DBProject
    Copy-Item $templateFolder\Template.DB.sln $nugetFolder\Template\Template.DB.sln
    Copy-Item $templateFolder\Template.DB.sln $nugetFolder\Template\.gitignore
    Initialize-NuGetSpec $nugetFolder $nugetSettings
    nuget pack $nugetFolder\Package.nuspec -BasePath $nugetFolder -OutputDirectory $testDrive\DevOpsTools | Out-Null
    nuget add $testDrive\DevOpsTools\$id.$version.nupkg -Source $nuGetSource | Out-Null
    Remove-Item TestDrive:\DevOpsTools\NuGet* -Force -Recurse
}
function New-Dep ($id, $version) {
    $nugetFolder = "$testDrive\DevOpsTools\NuGet\$id"
    $nugetSettings = Initialize-TestNugetConfig -NoDependencies
    $nugetSettings.nugetSettings.id = $id
    $nugetSettings.nugetSettings.version = $version
    Initialize-NuGetFolders $nugetFolder
    mkdir $nugetFolder\Databases | Out-Null
    $id | Out-File $nugetFolder\Databases\$id.dacpac
    Initialize-NuGetSpec $nugetFolder $nugetSettings
    nuget pack $nugetFolder\Package.nuspec -BasePath $nugetFolder -OutputDirectory $testDrive\DevOpsTools | Out-Null
    nuget add $testDrive\DevOpsTools\$id.$version.nupkg -Source $nuGetSource | Out-Null
	Remove-Item TestDrive:\DevOpsTools\NuGet* -Force -Recurse
	if (Test-Path $testDrive\DevOpsTools\$id.$version.nupkg)
    {
		Remove-Item $testDrive\DevOpsTools\$id.$version.nupkg -Force
	}
}

mkdir TestDrive:\DevOpsTools | Out-Null
Push-Location TestDrive:\DevOpsTools
$solutionsFolder = "$testDrive\Solutions"
mkdir $solutionsFolder | Out-Null
$solutionName = 'TestSolution'
$nuGetSource = "$testDrive\NuGetSource"
try {
    Install-DevOpsTools
    Install-TestReferences
    & .\New-CiDbProject.ps1 .\TestSolution.xml
} finally {
    Pop-Location
}
$location = $solutionsFolder
$name = $solutionName
$dbNames = @('db1', 'db2')
$deps = @{dep1='1.0.123'; dep2='1.0.234'}
#
# Validate DB project content
#
	Context "New project validation" {
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
		[xml]$prj = Get-Content "$location\$name\$($cs.ProjectPath)"
		It "Project header" {
			$prj.xml | should be $null
		}
	}
	
	$cs = Get-CSharpProjects -SolutionPath "$location\$name\$name.sln"
	[xml]$prj = Get-Content "$location\$name\$($cs.ProjectPath)"
	Context "Dependencies" {
		It "The specified properties were added" {
			($prj.Project.ItemGroup.PackageReference).Count | should be 4
		}
		Context "Versions" {
			$prj.Project.ItemGroup.PackageReference | ForEach-Object {
				if ($deps[$_.Include]) {
					It "$($_.Include) version" {
						$_.Version | should be $deps[$_.Include]
					}
				} else {
					It "$($_.Include) version" {
						$_.Version | should -Not -BeNullOrEmpty
					}
				}
			}
		}
	}

	$sql = Get-SqlProjects -SolutionPath "$location\$name\$name.sln"
	It "Two SQL projects are in the solution" {
		$sql.Count | should be 2
	}
	$sql | ForEach-Object {
		$projectName = $_.Project
		$projectPath = "$location\$name\$($_.ProjectPath)"
		$projectFolder = "$location\$name\$ProjectName"
		$projectNugetConfigPath = "$projectFolder\$projectName.nuget.config"
		$projText = Get-Content $projectPath | Out-String
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
			[xml]$nconfig = Get-Content $projectNugetConfigPath
			$nugetDbToolsRef = $nconfig.configuration.nugetDependencies.add | Where-Object { $_.key -eq 'NuGetDbPacker' }
			It "NuGetDbTools version" {
				$nugetDbToolsRef.value | should be $nugetDbToolsVersion
			}
			$deps.Keys | ForEach-Object {
				$dep = $_
				$ref = $nconfig.configuration.nugetDependencies.add | Where-Object { $_.key -eq $dep }
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
			$includes = ($proj.Project.ItemGroup.None | ForEach-Object { $_.Include })
			It "$($_.Project) NuGet configuration referenced from project file" {
				"$projectName.nuget.config" | should bein $includes
			}
			It "Template.DbProject NuGet configuration should not be referenced from project file" {
				"Template.DbProject.nuget.config" | should not bein $includes
			}
			$refs = $proj.Project.ItemGroup.ArtifactReference
			$deps.Keys + 'NugetDbPackerDb.Root' | ForEach-Object {
				$dep = $_
				Context "$dep database reference" {
					$ref = $refs | Where-Object { $_.Include -eq "..\Databases\$dep.dacpac"}
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
		'Bootstrap.ps1','Bootstrap.cmd', 'Get-PackageContent.ps1', 'GetPackageContent.cmd', 'Publish-DbProjects.ps1', 'PublishDbProjects.cmd' | ForEach-Object {
			It "PackageTools folder contains $_" {
				Test-Path "$location\$name\PackageTools\$_" | should be $true
			}
		}
	}
}