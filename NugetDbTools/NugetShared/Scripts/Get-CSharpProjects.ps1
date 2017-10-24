function Get-CSharpProjects {
    <#.Synopsis
        Get the solution's C# projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-CSharpProjects -SolutionPath .\EcsShared | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath
    )
    $csProjId = '{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $csProjId
    $newCsProjId = '{9A19103F-16F7-4668-BE54-9A1E7A4F7556}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $newCsProjId
}