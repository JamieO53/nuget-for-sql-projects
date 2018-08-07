powershell -Command ".\Invoke-RegressionTests.ps1; exit $LASTEXITCODE"
exit %errorlevel%