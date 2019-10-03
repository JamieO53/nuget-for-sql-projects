function Get-AssetLibraries($assets) {
    $libraries = $assets.libraries
    $lib = @{}
    $libraries | Get-Member | Where-Object { $_.MemberType -eq 'NoteProperty' } | ForEach-Object {
        $idVer = $_.Name.Split('/')
        $lib[$idVer[0]] = $idVer[1]
    }
    $lib    
}