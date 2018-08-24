cls

$nugetPath = "$env:LOCALAPPDATA\NuGet\NuGet.exe"

if (!(Get-Command NuGet -ErrorAction SilentlyContinue) -and !(Test-Path $nugetPath)) {
	Write-Host 'Downloading NuGet.exe'
	(New-Object System.Net.WebClient).DownloadFile("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe", $nugetPath)
}

if (Test-Path $nugetPath) {
	Set-Alias NuGet (Resolve-Path $nugetPath)
}

Write-Host 'Restore NuGet packages'
NuGet restore

#$env:GIT_SOLUTIONPATH = '..\..\TodoWeb\Todo.Web'
#$env:GIT_SOLUTIONPATH = $null
$needChangeDir = [String]::IsNullOrEmpty($env:GIT_SOLUTIONPATH)

if (!$needChangeDir) {
	Write-Host "Change to Solution Directory '$env:GIT_SOLUTIONPATH'"
	Set-Location "$env:GIT_SOLUTIONPATH"
} 

. '.\functions.ps1'

$invokeBuild = (Get-ChildItem(".\packages\Invoke-Build*\tools\Invoke-Build.ps1")).FullName | Sort-Object $_ | Select -Last 1
& $invokeBuild $args Tasks1.ps1 
