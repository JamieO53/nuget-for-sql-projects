function Get-ProjectsByType {
    <#.Synopsis
        Get the solution's projects of the specified type
    .DESCRIPTION
        Examines the Solution file and extracts a list of the project names and their locations relative to the solution
    .EXAMPLE
        Get-ProjectsByType -SolutionPath .\EcsShared -ProjId '{00D1A9C2-B5F0-4AF3-8072-F6C62B433612}' | % {
            $projName = $_.Project
            [xml]$proj = gc $_.ProjectPath
        }
    #>
    [CmdletBinding()]
    param
    (
        # The solution path
        [string]$SolutionPath,
        # The project type ID
        [string]$ProjId
    )
    [string]$sln=if ($SolutionPath -and (Test-Path $SolutionPath)) {gc $SolutionPath | Out-String} else {''}

    $nameGrouping = '(?<name>[^"]+)'
    $pathGrouping = '(?<path>[^"]+)'
    $guidGrouping = '(?<guid>[^\}]+)'
    $regex = "\r\nProject\(`"$ProjId`"\)\s*=\s*`"$nameGrouping`"\s*,\s*`"$pathGrouping`",\s*`"\{$guidGrouping\}`".*"
    $matches = ([regex]$regex).Matches($sln)

    $matches | % {
		$projName = $_.Groups['name'].Value
        $projPath = $_.Groups['path'].Value
        $projGuid = $_.Groups['guid'].Value
        New-Object -TypeName PSObject -Property @{
            Project = $projName;
            ProjectPath = $projPath;
            ProjectGuid = $projGuid
        }
    }
}