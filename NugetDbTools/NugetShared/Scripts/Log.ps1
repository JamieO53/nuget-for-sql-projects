[String]$script:logPath=$null
function Log {
    [CmdletBinding()]
	param (
		[string]$logMsg=$null,
		[string]$task=$null,
		[string]$taskStep=$null,
		[string]$fg=$null,
		[switch]$Warn, [switch]$Error, [switch]$hilite, [switch]$stdoutOnly, [switch]$allowLayout
	)
	if ([string]::IsNullOrEmpty($task)) {
		$task = [IO.Path]::GetFileNameWithoutExtension((Get-PSCallStack | Select-Object -Last 1).ScriptName)
	}
	if ([string]::IsNullOrEmpty($taskStep)) {
		$taskStep = Get-Caller
	}

	$level='I'
	if ($hilite)
	{
		$level+='!'
	}

	if (-not $allowLayout -and [string]::IsNullOrEmpty($logMsg))
	{
		$logMsg="Log message argument expected!"
		if (-not $Error)
		{
			$warn=$true
		}
	}
	
	if ($Error)
		{$level='E'; $fg='red'}
	elseif ($Warn)
		{$level='W'; if ($debug) {$fg='magenta'} else {$fg='yellow'}}
	elseif ($hilite)
		{if ($debug) {$fg='black'} else {$fg='white'}}
	elseif ($debug)
		{$fg='black'} 
	elseif (-not $fg)
		{$fg='gray'}

	$msg = "[$task][$taskStep][$level] $logMsg".Replace('[]','')
	if (-not $stdoutOnly) {
		if ([string]::IsNullOrEmpty($script:logPath)) {
			$log = [IO.Path]::GetFileNameWithoutExtension($MyInvocation.PSCommandPath)
			$script:logPath = Get-LogPath $log
		}
		Out-File $script:logPath -InputObject $msg -Encoding ascii -Append -NoClobber -Width 1024
	}
	Write-Host $msg -ForegroundColor $fg
}
