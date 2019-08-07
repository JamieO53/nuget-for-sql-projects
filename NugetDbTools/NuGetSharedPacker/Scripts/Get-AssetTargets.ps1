function Get-AssetTargets($assets) {
    $targets = $assets.targets.'.NETStandard,Version=v1.4'
    $tgt = @{}
    $targets | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % {
        $idVer = $_.Name
        $id = $idVer.Split('/')[0]
        $info = iex "`$targets.'$idVer'"
        if ($info.dependencies) {
            $targetDependencies = $info.dependencies | ? { $_ } | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % {
                $_.Name
            }
            $tgt[$id] = $targetDependencies
        } else {
            $tgt[$id] = $null
        }
    }
    $tgt
}