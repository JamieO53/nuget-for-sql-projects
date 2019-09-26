if ( Get-Module NugetShared) {
	Remove-Module NugetShared
}
Import-Module "$PSScriptRoot\..\bin\Debug\NugetShared\NugetShared.psm1" -Global -DisableNameChecking

$solutionText = @"
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 15
VisualStudioVersion = 15.0.26730.12
MinimumVisualStudioVersion = 10.0.40219.1
Project("{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}") = "EcsShared.SharedBase", "EcsCore\EcsShared.SharedBase.sqlproj", "{0B09815E-5872-4779-9EB3-E4E98E86A098}"
EndProject
Project("{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}") = "EcsShared.SupportRoles", "SupportRoles\EcsShared.SupportRoles.sqlproj", "{F8355DBB-9029-4D87-BE3C-47AE65BA3C3B}"
EndProject
Project("{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}") = "TSQLUnit", "TSQLUnit\TSQLUnit.sqlproj", "{1935F3C1-DA29-4347-8747-C20C29E96026}"
EndProject
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "Solution Items", "Solution Items", "{6E4297E2-4E5C-4CE9-A3D1-B68AB3436348}"
	ProjectSection(SolutionItems) = preProject
		packages.config = packages.config
	EndProjectSection
EndProject
"@
$expected = @()
$expected += New-Object -TypeName psobject -Property @{Project = 'EcsShared.SharedBase';ProjectPath = 'EcsCore\EcsShared.SharedBase.sqlproj'}
$expected += New-Object -TypeName psobject -Property @{Project = 'EcsShared.SupportRoles';ProjectPath = 'SupportRoles\EcsShared.SupportRoles.sqlproj'}
$expected += New-Object -TypeName psobject -Property @{Project = 'TSQLUnit';ProjectPath = 'TSQLUnit\TSQLUnit.sqlproj'}

$slnFolder = 'TestDrive:\sln'
$slnPath = "$slnFolder\solution.sln"
Describe "Get-SqlProjects" {
    Context "Get solution SQL projects" {
        mkdir $slnFolder
        $solutionText | Set-Content $slnPath -Encoding UTF8
        $actual = Get-SqlProjects -SolutionPath $slnPath
        Context "Actual projects as expected" {
            $actual | % {
                $actProj = $_.Project
                $actPath = $_.ProjectPath
                $exp = $expected | ? { $_.Project -eq $actProj }
                It "$actProj was expected" { $exp | should not BeNullOrEmpty }
                It "$actProj path" { $exp.ProjectPath | should be $actPath }
            }
        }
        Context "Expected projects are actual" {
            $expected | % {
                $expProj = $_.Project
                $expPath = $_.ProjectPath
                $act = $actual | ? { $_.Project -eq $expProj }
                It "$expProj was expected" { $act | should not BeNullOrEmpty }
                It "$expProj path" { $act.ProjectPath | should be $expPath }
            }
        }
        rmdir $slnFolder\* -Recurse -Force
    }
}