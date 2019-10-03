function Find-SqlPackagePath {
	[IO.FileInfo]$info
	Get-ChildItem "$env:ProgramFiles*\Microsoft Visual Studio\*\*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
		Sort-Object -Property FullName -Descending |
		Select-Item -First 1 | ForEach-Object {
			$info = $_
		}
	if ($info -eq $null)  {
		Get-ChildItem "$env:ProgramFiles*\Microsoft SQL Server\*\DAC\bin\SqlPackage.exe" |
			Sort-Object -Property FullName -Descending |
			Select-Item -First 1 | ForEach-Object {
			$info = $_
		}
	}
	if ($info -eq $null)  {
		Get-ChildItem "$env:ProgramFiles*\Microsoft Visual Studio*\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\*\SqlPackage.exe" |
			Sort-Object -Property FullName -Descending |
			Select-Item -First 1 | ForEach-Object {
			$info = $_
		}
	}
    if ($info) {
		return $info.FullName.Trim()
	} else {
		return $null
	}
}
