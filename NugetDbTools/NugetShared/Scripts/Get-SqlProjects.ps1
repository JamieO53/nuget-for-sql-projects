function Get-SqlProjects {
    <#.Synopsis
        Get the solution's SQL projects
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-SqlProjects -SolutionPath .\EcsShared | ForEach-Object {
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
    $sqlProjId = '{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}'
    Get-ProjectsByType -SolutionPath $SolutionPath -ProjId $sqlProjId
}