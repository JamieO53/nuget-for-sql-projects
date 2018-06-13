function Find-SqlPackagePath {
	[IO.FileInfo]$info
	ls "$env:ProgramFiles*\Microsoft Visual Studio\*\*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
		sort -Property FullName -Descending |
		select -First 1 | % {
			$info = $_
		}
	if ($info -eq $null)  {
		ls "$env:ProgramFiles*\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe" |
			sort -Property FullName -Descending |
			select -First 1 | % {
			$info = $_
		}
	}
	if ($info -eq $null)  {
		ls "$env:ProgramFiles*\Microsoft Visual Studio*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
			sort -Property FullName -Descending |
			select -First 1 | % {
			$info = $_
		}
	}
    if ($info) {
		return $info.FullName
	} else {
		return $null
	}
}
