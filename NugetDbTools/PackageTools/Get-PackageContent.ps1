$SolutionFolder = Resolve-Path "$(Split-Path -Path $MyInvocation.MyCommand.Path)\.."
[string]$slnPath=ls $SolutionFolder\*.sln | ? { $_ } | % { $_.FullName }

if ( Get-Module NugetDbPacker) {
	Remove-Module NugetDbPacker
}
Import-Module "$SolutionFolder\PowerShell\NugetDbPacker.psd1"

Get-CSharpProjects -SolutionPath $slnPath | ? { $_.Project.EndsWith('Pkg') } | % {
    $projFolder = Split-Path "$SolutionFolder\$($_.ProjectPath)"
    $projAssetsPath = "$projFolder\obj\project.assets.json"
    $projAssetsText = gc $projAssetsPath | Out-String
    $projAssets = ConvertFrom-Json $projAssetsText
    $packagesPath = $projAssets.project.restore.packagesPath
    $targets = @{}
    $projAssets.targets.'.NETStandard,Version=v1.4' | Get-Member | ? {
        ($_.MemberType -eq 'NoteProperty') } | % {
            $nameVersion = $_.Name.Split('/')
            $targets[$nameVersion[0]] = $nameVersion[1]
        }

    $cleared = @{}
    $projAssets.project.frameworks.'netstandard1.4'.dependencies | Get-Member | ? {
        ($_.MemberType -eq 'NoteProperty') -and ($_.Name -ne 'NETStandard.Library') } | % {
            $packageName = $_.Name
            $packageVersion = $targets[$packageName]
            $packagePath = "$packagesPath$packageName\$packageVersion"
            
            ls $packagePath -Directory | % {
                if (-not $cleared[$_.Name]) {
                    del "$SolutionFolder\$($_.Name)\*" -Recurse -Force
                    $cleared[$_.Name] = $true
                }
                copy -Path $_.FullName -Destination $SolutionFolder -Force -Recurse -Container
            }
            Get-SqlProjects -SolutionPath $slnPath | % {
                $progNugetConfigPath = [IO.Path]::ChangeExtension("$SolutionFolder\$($_.ProjectPath)" , '.nuget.config')
                [xml]$cfg = gc $progNugetConfigPath
                $deps = $cfg.configuration.nugetDependencies
                if ($deps -and $deps.add) {
                    $deps.add | ? { ($_.key -eq $packageName) -and ($_.value -ne $packageVersion ) } | % {
                        $_.value = $packageVersion
                        Out-FormattedXml -Xml $cfg -FilePath $progNugetConfigPath
                    }
                }
            }
        }
}
