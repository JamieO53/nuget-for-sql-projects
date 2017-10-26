$SolutionFolder = Split-Path -Path $MyInvocation.MyCommand.Path
$SolutionPath = ls "$SolutionFolder\*.sln"
if (-not (Get-Module NuGetShared)) {
	Import-Module "$SolutionFolder\NugetShared\bin\Debug\NuGetShared\NuGetShared.psd1"
}
if (-not (Test-Path "$SolutionFolder\TestResults\HTML")) {
	md "$SolutionFolder\TestResults\HTML"
}
$allTests = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Results</title>
  </head>
	<ul>
		$links
	</ul>
  <body>
  </body>
</html>
"@
$links = ''
Get-PowerShellProjects -SolutionPath $SolutionPath | % {
	$projectFolder = Split-Path "$SolutionFolder\$($_.ProjectPath)"
	if (Test-Path "$projectFolder\Tests")
	{
		if (Get-Module NuGetShared) {
			Remove-Module NuGetShared
		}
		Invoke-Pester "$projectFolder\Tests" -OutputFile "$SolutionFolder\TestResults\$($_.Project).xml" -OutputFormat NUnitXml
		& NUnitHTMLReportGenerator.exe "$SolutionFolder\TestResults\$($_.Project).xml" "$SolutionFolder\TestResults\HTML\$($_.Project).html"
		if (Test-Path "$SolutionFolder\TestResults\HTML\$($_.Project).html") {
			$links += @"
		<li><a href=`"$($_.Project).html`">$($_.Project)</a></li>
"@
		}
		if (Test-Path variable:\global:testing) {
			$Global:testing = $false
		}
		if (Get-Module $_.Project) {
			Remove-Module $_.Project
		}
	}
}
$allTests = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>Results</title>
  </head>
	<ul>
		$links
	</ul>
  <body>
  </body>
</html>
"@
$allTests | Out-File "$SolutionFolder\TestResults\HTML\TestResults.html"