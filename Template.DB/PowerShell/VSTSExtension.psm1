
function Test-IsRunningBuildAgent {
	if ($env:USERNAME -eq 'VssAdministrator') {
		$true
	} else {
		$buildAgent = (
			get-service | Where-Object {
				($_.Status -eq 'Running') -and ($_.Name -like 'vstsagent.*')
			} | ForEach-Object {
				$_.Name
			}
		)
		-not ([string]::IsNullOrEmpty($buildAgent))
	}
}