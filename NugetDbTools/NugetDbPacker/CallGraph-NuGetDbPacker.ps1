$moduleName='NuGetDbPacker'
$heads = @() #@('Publish-SolutionDbPackages')
$externals = @()

$scriptName="$moduleName.psm1"
$scriptFile="$env:GithubRepositories\nuget-for-sql-projects\NugetDbTools\$moduleName\bin\Debug\$moduleName\$scriptName"
$callGraphPath = [IO.Path]::GetFullPath("$ENV:GithubRepositories\powershell-scripted-functions\CallGraph")

$heads = @('Publish-SolutionDbPackages','Get-SolutionContent','Initialize-TestNugetConfig')
$externals = @()
$label = "$moduleName"

& "$callGraphPath\CallGraph.ps1" -Path $scriptFile -GraphHeads $heads -Label $label -ExternalReferences $externals |
	Out-File ".\CallGraph-$moduleName.txt" -Encoding utf8
gc ".\CallGraph-$moduleName.txt" | dot.exe -Tpng -o"CallGraph_$moduleName.png"
gc ".\CallGraph-$moduleName.txt" | dot.exe -Tpdf -o"CallGraph_$moduleName.pdf"