function Test-IsRunningBuildAgent {
	if ($env:USERNAME -eq 'VssAdministrator') {
		$true
	} else {
		$buildAgent = (
			get-service | ? {
				($_.Status -eq 'Running') -and ($_.Name -like 'vstsagent.*')
			} | % {
				$_.Name
			}
		)
		-not ([string]::IsNullOrEmpty($buildAgent))
	}
}
