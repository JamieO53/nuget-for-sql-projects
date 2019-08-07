function Get-AssetLibraries($assets) {
    $libraries = $assets.libraries
    $lib = @{}
    $libraries | Get-Member | ? { $_.MemberType -eq 'NoteProperty' } | % {
        $idVer = $_.Name.Split('/')
        $lib[$idVer[0]] = $idVer[1]
    }
    $lib    
}