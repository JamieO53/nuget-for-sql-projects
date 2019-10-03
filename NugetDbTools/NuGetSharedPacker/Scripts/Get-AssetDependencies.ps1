function Get-AssetDependencies($assets) {
    $dependencies = $assets.project.frameworks.'netstandard1.4'.dependencies
    $dep = @{}
    $dependencies | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | Where-Object {
        $id = $_.Name
        $info = Invoke-Expression "`$dependencies.'$id'"
        -not $info.autoReferenced
    } | ForEach-Object {
        $id = $_.Name
        $info = Invoke-Expression "`$dependencies.'$id'"
        $dep[$id] = $info.version
    }
    $dep
}