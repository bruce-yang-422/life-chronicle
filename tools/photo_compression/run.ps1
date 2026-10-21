param(
    [string]$Device = 'emulator-5554',
    [string]$JdkRoot = 'C:\Program Files\Android\Android Studio\jbr',
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\sdk"
)
$ErrorActionPreference = 'Stop'
function Invoke-Checked([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $Executable ($LASTEXITCODE)" }
}
$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runId = [guid]::NewGuid().ToString('N').Substring(0, 8)
$output = Join-Path $workspace "build\photo_compression\run_$runId"
$deviceDirectory = "/data/local/tmp/life_chronicle_photos_$runId"
$androidJar = Join-Path $SdkRoot 'platforms\android-36\android.jar'
$adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
Push-Location $workspace
try {
    New-Item -ItemType Directory -Force -Path "$output\classes", "$output\dex" | Out-Null
    Invoke-Checked (Join-Path $JdkRoot 'bin\javac.exe') @('--release', '8', '-cp', $androidJar,
        '-d', "$output\classes", 'tools/photo_compression/PhotoCompressionCheck.java',
        'android/app/src/main/java/io/github/bruce_yang_422/life_chronicle/PhotoProcessor.java')
    $classes = @(Get-ChildItem -LiteralPath "$output\classes" -Recurse -Filter '*.class' | ForEach-Object { $_.FullName })
    Invoke-Checked (Join-Path $JdkRoot 'bin\java.exe') (@('-cp', (Join-Path $SdkRoot 'build-tools\36.0.0\lib\d8.jar'),
        'com.android.tools.r8.D8', '--min-api', '30', '--lib', $androidJar, '--output', "$output\dex") + $classes)
    Invoke-Checked $adb @('-s', $Device, 'shell', 'mkdir', $deviceDirectory)
    Invoke-Checked $adb @('-s', $Device, 'push', "$output\dex\classes.dex", "$deviceDirectory/classes.dex")
    Invoke-Checked $adb @('-s', $Device, 'shell', "CLASSPATH=$deviceDirectory/classes.dex app_process /system/bin PhotoCompressionCheck $deviceDirectory")
    Invoke-Checked $adb @('-s', $Device, 'pull', "$deviceDirectory/report.json", "$output\report.json")
    Write-Output "Evidence: $output\report.json"
    # Retain isolated evidence; never delete user or application data.
} finally { Pop-Location }
