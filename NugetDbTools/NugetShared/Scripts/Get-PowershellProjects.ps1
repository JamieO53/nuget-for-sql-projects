function Get-PowerShellProjects {
    <#.Synopsis
        Get the solution's C# projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-PowerShellProjects -SolutionPath .\EcsShared | ForEach-Object {
            $projName = $_.Project
            [xml]$proj = Get-Content $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath
    )
    $csProjId = '{F5034706-568F-408A-B7B3-4D38C6DB8A32}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $csProjId
}