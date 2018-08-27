@{
	ProjectName = 'NuGetSharedPacker'
	ProjectType = ''
	Dependencies = @('NuGetShared')
	Extensions = @('GitExtension','VSTSExtension')
	Dependents = @('NuGetDbPacker','NuGetProjectPacker')
}