Describe "Test-IsRunningBuildAgent" {
	Context "Build agent service" {
		It "Is not running" {
			Test-IsRunningBuildAgent | Should Be ($env:USERNAME -eq 'Builder')
		}
	}
}