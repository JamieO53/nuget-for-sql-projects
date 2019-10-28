function Import-Extensions {
    $extensions = Get-ExtensionPaths
    $extensions.Keys | ForEach-Object {
        $extension = $_
        $extensionPath = $extensions[$_]
        if (-not (Get-Module $extension -All)) {
            if (Test-Path $extensionPath) {
                Import-Module $extensionPath -Global -DisableNameChecking
            } else {
                throw "Unable to import extension $extension"
            }
        }
    }
}