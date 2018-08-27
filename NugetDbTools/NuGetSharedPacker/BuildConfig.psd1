@{
	ProjectName = 'NuGetSharedPacker'
	Dependencies = @('NuGetShared')
	Extensions = @('GitExtension','VSTSExtension')
	Dependents = @('NuGetDbPacker','NuGetProjectPacker')
}