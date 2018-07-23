$SolutionFolder = Split-Path -Path $MyInvocation.MyCommand.Path
$SolutionPath = ls "$SolutionFolder\*.sln"
if (Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
if (Get-Module NuGetShared) {
	Remove-Module NuGetShared
}
if (-not (Get-Module NuGetShared)) {
	Import-Module "$SolutionFolder\NugetShared\bin\Debug\NuGetShared\NuGetShared.psd1"
}
if (Get-Module NuGetSharedPacker) {
	Remove-Module NuGetSharedPacker
}
if (-not (Get-Module NuGetSharedPacker)) {
	Import-Module "$SolutionFolder\NugetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1"
}
if (Test-Path "$SolutionFolder\TestResults") {
	rmdir "$SolutionFolder\TestResults\*" -Recurse -Force
}
mkdir "$SolutionFolder\TestResults\HTML" | Out-Null

$links = ''
$results = @{}
$statistics = @()
$failCount = 0
$renderHtml = $true

Get-PowerShellProjects -SolutionPath $SolutionPath | % {
	$projectFolder = Split-Path "$SolutionFolder\$($_.ProjectPath)"
	$testName = $_.Project
	if (Test-Path "$projectFolder\Tests")
	{
		if (Get-Module TestUtils) {
			Remove-Module TestUtils
		}
		if (Get-Module NuGetShared) {
			Remove-Module NuGetShared
		}
		Import-Module "$SolutionFolder\NugetShared\bin\Debug\NuGetShared\NuGetShared.psd1" 
		if (Get-Module NuGetSharedPacker) {
			Remove-Module NuGetSharedPacker
		}
		Import-Module "$SolutionFolder\NuGetSharedPacker\bin\Debug\NuGetSharedPacker\NuGetSharedPacker.psd1" 
		pushd "$projectFolder\Tests"
		$testResult = Invoke-Pester "$projectFolder\Tests" -OutputFile "$SolutionFolder\TestResults\$($_.Project).xml" -OutputFormat NUnitXml -PassThru -EnableExit
		$failCount = $failCount + $testResult.FailedCount
		popd
		$statistic = New-Object -TypeName PSObject -Property @{
			Name=$testName;
			TotalCount=$testResult.TotalCount;
			PassedCount=$testResult.PassedCount;
			FailedCount=$testResult.FailedCount;
			SkippedCount=$testResult.SkippedCount;
			PendingCount=$testResult.PendingCount;
			InconclusiveCount=$testResult.InconclusiveCount;
			Time=$testResult.Time;
			TimeTicks=$testResult.Time.Ticks
		}
		$statistics += $statistic
		try {
		& NUnitHTMLReportGenerator.exe "$SolutionFolder\TestResults\$($_.Project).xml" "$SolutionFolder\TestResults\HTML\$($_.Project).html"
		} catch {
			$renderHtml = $false
		}
		if (Test-Path "$SolutionFolder\TestResults\HTML\$($_.Project).html") {
			$links += @"
		<tr>
			<td align="left"><a href=`"$($_.Project).html`">$($_.Project)</a></td>
			<td align="right">$($statistic.TotalCount)</td>
			<td align="right">$($statistic.PassedCount)</td>
			<td align="right">$($statistic.FailedCount)</td>
			<td align="right">$($statistic.SkippedCount)</td>
			<td align="right">$($statistic.PendingCount)</td>
			<td align="right">$($statistic.InconclusiveCount)</td>
			<td align="left">$($statistic.Time)</td>
		</tr>
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
$total = @{Name='Total'}
$statistics |
	Measure-Object -Property TotalCount,PassedCount,FailedCount,SkippedCount,PendingCount,InconclusiveCount,TimeTicks -sum | % {
		$total[$_.Property] = $_.Sum
	}
$total['Time'] = [timespan]::new($total['TimeTicks'])
$totalStatistic = New-Object -TypeName PSObject -Property $total
$statistics += $totalStatistic

$allTests = @"
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1" />
    <title>NuGetDbTools Tests</title>
  </head>
  <body>
	<h1>NuGetDbTools test results</h1>
	<table>
		<tr>
			<thead>
				<th align="left">Name</th>
				<th align="left">TotalCount</th>
				<th align="left">PassedCount</th>
				<th align="left">FailedCount</th>
				<th align="left">SkippedCount</th>
				<th align="left">PendingCount</th>
				<th align="left">InconclusiveCount</th>
				<th align="left">Time</th>
			</thead>
		</tr>
$links
		<tr>
			<td align="left">$($total['Name'])</td>
			<td align="right">$($total['TotalCount'])</td>
			<td align="right">$($total['PassedCount'])</td>
			<td align="right">$($total['FailedCount'])</td>
			<td align="right">$($total['SkippedCount'])</td>
			<td align="right">$($total['PendingCount'])</td>
			<td align="right">$($total['InconclusiveCount'])</td>
			<td align="left">$($total['Time'])</td>
		</tr>
	</table>
  </body>
</html>
"@
$allTests | Out-File "$SolutionFolder\TestResults\HTML\TestResults.html" -Force
if ($renderHtml) {
	iex "$SolutionFolder\TestResults\HTML\TestResults.html"
}
$statistics | Format-Table -Property Name,TotalCount,PassedCount,FailedCount,SkippedCount,PendingCount,InconclusiveCount,Time
Write-Host "Fail count: $failCount"
exit $failCount