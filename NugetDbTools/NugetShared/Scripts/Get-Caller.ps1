function Get-Caller {
	(Get-PSCallStack | Select-Object -First 3 | Select-Object -Last 1).Command
}