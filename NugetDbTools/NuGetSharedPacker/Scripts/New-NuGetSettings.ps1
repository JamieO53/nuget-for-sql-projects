function New-NuGetSettings {
	New-Object -TypeName PSObject -Property @{
		nugetOptions = New-Object -TypeName PSObject -Property @{
				majorVersion = '';
				minorVersion = '';
				contentFolders = '';
			};
		nugetSettings = @{};
		nugetDependencies = @{}
		nugetContents = @{}
	}
}