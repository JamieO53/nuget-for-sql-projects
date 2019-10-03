function Get-AssetTargets($assets) {
    $targets = $assets.targets.'.NETStandard,Version=v1.4'
    $tgt = @{}
    $targets | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
        $idVer = $_.Name
        $id = $idVer.Split('/')[0]
        $info = Invoke-Expression "`$targets.'$idVer'"
        if ($info.dependencies) {
            $targetDependencies = $info.dependencies | Where-Object { $_ } | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
                $_.Name
            }
            $tgt[$id] = $targetDependencies
        } else {
            $tgt[$id] = $null
        }
    }
    $tgt
}