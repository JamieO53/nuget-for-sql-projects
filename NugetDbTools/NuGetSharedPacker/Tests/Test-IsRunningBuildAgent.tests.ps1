Describe "Test-IsRunningBuildAgent" {
	Context "Build agent service" {
		It "Is not running" {
			Test-IsRunningBuildAgent | Should Be $false
		}
	}
}