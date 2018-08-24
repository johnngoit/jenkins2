function Get-SolutionProjects
{
	#'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
	Add-Type -Path (${env:ProgramFiles(x86)} + '\Reference Assemblies\Microsoft\MSBuild\v14.0\Microsoft.Build.dll')

	$solutionFile = (Get-ChildItem('*.sln')).FullName | Select -First 1
	$solution = [Microsoft.Build.Construction.SolutionFile] $solutionFile

	return $solution.ProjectsInOrder |
		Where-Object {$_.ProjectType -eq 'KnownToBeMSBuildFormat'} | 
		ForEach-Object {
			$isWebProject = (Select-String -Pattern "<UseIISExpress>.+</UseIISExpress>" -Path $_.AbsolutePath) -ne $null
			@{
				Path = $_.AbsolutePath;
				Name = $_.ProjectName;
				Directory = "$(Split-Path -Path $_.AbsolutePath -Resolve)";
				IsWebProject = $isWebProject;
			}
		}
}

function Get-PackagePath($packageId, $projectPath) {
	if (!(Test-Path "$projectPath\packages.config")){
		throw "Could not find a packages.config file at $project"
	}

	[xml]$packagesXml = Get-Content "$projectPath\packages.config"
	$package = $packagesXml.packages.package | Where { $_.id -eq $packageId }
	if (!$package) {
		return $null
	}
	return "packages\$($package.id).$($package.version)"
}

function Get-Version($projectPath) {
	$line = Get-Content "$projectPath\Properties\AssemblyInfo.cs" | Where { $_.Contains("AssemblyVersion") }
	if (!$line) {
		throw "Couldn't find an AssemblyVersion attribute"
	}
	$version = $line.Split('"')[1]

	$isLocal = [String]::IsNullOrEmpty($env:BUILD_SERVER)

	if ($isLocal) {
		$preRelease = $(Get-Date).ToString("yyMMddHHmmss")
		$version = "$($version.Replace("*", 0))-preRelease"
	} else {
		$version = "$($version.Replace("*", $env:BUILD_NUMBER))"
	}
	return $version
}

# nuget restore, clean solution, and build solution
# buildVS .\path\to\solution.sln
# clean solution and build solution
#buildVS .\path\to\solution.sln $false $true
# build solution
#buildVS -path .\path\to\solution.sln -nuget $false -clean $false
# nuget restore and build solution
#buildVS -path .\path\to\solution.sln -clean $false
#https://knightcodes.com/miscellaneous/2016/09/05/build-solutions-and-projects-with-powershell.html
#https://www.youtube.com/watch?v=2Ngvr79QbsU
function buildVS
{
    param
    (
        [parameter(Mandatory=$true)]
        [String] $path,

        [parameter(Mandatory=$false)]
        [bool] $nuget = $true,
        
        [parameter(Mandatory=$false)]
        [bool] $clean = $true
    )
    process
    {
        #$msBuildExe = 'C:\Program Files (x86)\MSBuild\14.0\Bin\msbuild.exe'
		$msBuildExe = 'C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe'
		$nuget = "$env:LOCALAPPDATA\NuGet\NuGet.exe"

        if ($nuget) {
            Write-Host "Restoring NuGet packages" -foregroundcolor green
            nuget restore "$($path)"
        }

        if ($clean) {
            Write-Host "Cleaning $($path)" -foregroundcolor green
            & "$($msBuildExe)" "$($path)" /t:Clean /m
        }

        Write-Host "Building $($path)" -foregroundcolor green
        & "$($msBuildExe)" "$($path)" /t:Build /m
    }
}