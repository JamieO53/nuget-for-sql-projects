param(
	[string]$project = 'CI-Common',
	[string]$path = '.',
	[string]$outputPath = '.\CI-Common\bin\Debug'
)

function Get-ProjectFunctionIncludes {
	param (
		[xml]$proj
	)
	$proj.Project.ItemGroup.Compile |
		where {
			[string]$path = $_.Include
			$path.EndsWith('ps1') -and -not $path.Contains('.tests.') -and $path.Contains('\')
		}	
}

function Get-ProjectFunctionText {
	param (
		[xml]$proj
	)
	[string]$body = ''
	Get-ProjectFunctionIncludes -proj $proj | % {
			[string]$fn = Get-Content "$path\$project\$($_.Include)" | Out-String
			$body += "$fn
"
		}
	$body
}

$projFile = "$path\$project\$project.pssproj"
if (Test-Path $projFile) {
	try {
		[xml]$proj = Get-Content $projFile
		$body = Get-ProjectFunctionText -proj $proj
		$moduleTemplate = "$path\$project\$project.psm1"
		$moduleOutputPath = "$outputPath\$project"
		
		if (Test-Path $moduleOutputPath) {
			Remove-Item -Path $moduleOutputPath -Recurse -Force
		}
		
		if (Test-Path "$path\$project\$project.psm1") {
			if (-not (Test-Path $moduleOutputPath)) {
				mkdir $moduleOutputPath | Out-Null
		    }
			$moduleFile = "$moduleOutputPath\$project.psm1"
			[string]$moduleBody = Get-Content $moduleTemplate | Out-String
			"$moduleBody
$body" | Out-File $moduleFile -Encoding utf8
		}
		
	}
	catch {
		throw $_.Exception
	}
}