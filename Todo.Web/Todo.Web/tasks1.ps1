param (
	$outputDirectory = (property outputDirectory "artifacts"),
	$configuration = 'Release',
	$msBuildExe = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
)

$absoluteOutputDirectory = "$((Get-Location).Path)\$outputDirectory"
$projects = Get-SolutionProjects

Task Clean {
	if((Test-Path $absoluteOutputDirectory)) {
		Write-Host "Cleaning artifacts $absoluteOutputDirectory"
		Remove-Item "$absoluteOutputDirectory" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
	}
	New-Item $absoluteOutputDirectory -ItemType Directory | Out-Null
	
	$projects |
		ForEach-Object {
			Write-Host "Cleaning bin and obj $($_.Directory)"
			Remove-Item "$($_.Directory)\bin" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
			Remove-Item "$($_.Directory)\obj" -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
		}
}

Task Compile {
	#use "14.0" MSBuild
	#buildVS -path .\path\to\solution.sln -nuget $false -clean $false
	$projects |
		ForEach-Object {

			if($_.IsWebProject){
				$webOutDir = "$absoluteOutputDirectory\$($_.Name)"
				$outDir = "$absoluteOutputDirectory\$($_.Name)\bin"
				Write-Host "Compiling $($_.Name) to $outDir"
				#exec {MSBuild "$($_.Path)" /p:Configuration=$configuration /p:OutDir=$outDir /p:WebProjectOutputDir=$webOutDir `
				#						 /nologo /p:DebugType=None /p:Platform=AnyCpu /verbosity:quiet }

				#'/t:Clean,Build'
				&"$msbuildExe" ("$($_.Path)","/p:OutDir=$outDir", "/p:WebProjectOutputDir=$webOutDir", '/verbosity:q',"/p:configuration=$configuration",'/t:Build')
				if (!$?) {
					echo "!!! ABORTING !!!";pause;exit    
				}
			} else {
				$outDir = "$absoluteOutputDirectory\$($_.Name)"
				Write-Host "Compiling $($_.Name) to $outDir"
				&"$msbuildExe" ("$($_.Path)","/p:OutDir=$outDir", '/verbosity:q',"/p:configuration=$configuration",'/t:Build')
				if (!$?) {
					echo "!!! ABORTING !!!";pause;exit    
				}
			}
		}
}

Task Test {
	$projects |
		ForEach-Object {
			$xunitPath = Get-PackagePath "xunit.runner.console" $($_.Directory)
			if($xunitPath -eq $null) {
				return
			}
			$xunitRunner = "$xunitPath\tools\xunit.console.exe"
			exec { & $xunitRunner $absoluteOutputDirectory\$($_.Name)\$($_.Name).dll `
					-xml "$absoluteOutputDirectory\xunit_$($_.Name).xml" `
					-html "$absoluteOutputDirectory\xunit_$($_.Name).html" `
					-nologo }
		}
}

Task Pack {
	$projects |
		ForEach-Object {
			$octopusToolsPath = Get-PackagePath "OctopusTools" $($_.Directory)
			if ($octopusToolsPath -eq $null) {
				return
			}
			$version = Get-Version $_.Directory
			exec { & $octopusToolsPath\tools\Octo.exe pack `
						--basePath=$absoluteOutputDirectory\$($_.Name) `
						--outFolder=$absoluteOutputDirectory --id=$($_.Name) `
						--overwrite `
						--version=$version }
		}
}

Task dev clean, compile, test, pack

Task ci dev