function Get-AssetDependencies($assets) {
    $dependencies = $assets.project.frameworks.'netstandard1.4'.dependencies
    $dep = @{}
    $dependencies | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | ? {
        $id = $_.Name
        $info = iex "`$dependencies.'$id'"
        -not $info.autoReferenced
    } | % {
        $id = $_.Name
        $info = iex "`$dependencies.'$id'"
        $dep[$id] = $info.version
    }
    $dep
}