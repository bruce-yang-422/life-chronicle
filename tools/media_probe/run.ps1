param(
    [string]$Device = 'emulator-5554',
    [string]$FlutterRoot = 'C:\flutter',
    [string]$JdkRoot = 'C:\Program Files\Android\Android Studio\jbr',
    [string]$SdkRoot = "$env:LOCALAPPDATA\Android\sdk"
)

$ErrorActionPreference = 'Stop'
function Invoke-MediaCommand([string]$Executable, [string[]]$ArgumentList) {
    & $Executable @ArgumentList
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $Executable ($LASTEXITCODE)" }
}

$workspace = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runId = [guid]::NewGuid().ToString('N').Substring(0, 8)
$output = Join-Path $workspace "build\media_probe_native\run_$runId"
$samples = Join-Path $output 'samples'
$deviceDirectory = "/data/local/tmp/life_chronicle_media_probe_$runId"
$adb = Join-Path $SdkRoot 'platform-tools\adb.exe'
$java = Join-Path $JdkRoot 'bin\java.exe'
$javac = Join-Path $JdkRoot 'bin\javac.exe'
$dart = Join-Path $FlutterRoot 'bin\dart.bat'
$flutter = Join-Path $FlutterRoot 'bin\flutter.bat'
$androidJar = Join-Path $SdkRoot 'platforms\android-36\android.jar'
$d8 = Join-Path $SdkRoot 'build-tools\36.0.0\lib\d8.jar'

Push-Location $workspace
try {
    New-Item -ItemType Directory -Force -Path "$output\classes", "$output\dex" | Out-Null
    Set-Content -LiteralPath "$output\device_path.txt" -Value $deviceDirectory -Encoding ASCII
    Invoke-MediaCommand -Executable $javac -ArgumentList @('--release', '8', '-cp', $androidJar,
        '-d', "$output\classes", 'tools/media_probe/NativeMediaSamples.java')
    Invoke-MediaCommand -Executable $java -ArgumentList @('-cp', $d8, 'com.android.tools.r8.D8',
        '--min-api', '26', '--lib', $androidJar, '--output', "$output\dex", "$output\classes\NativeMediaSamples.class")
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'shell', 'mkdir', $deviceDirectory)
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'push', "$output\dex\classes.dex", "$deviceDirectory/classes.dex")
    $nativeCommand = "CLASSPATH=$deviceDirectory/classes.dex app_process /system/bin NativeMediaSamples $deviceDirectory"
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'shell', $nativeCommand)
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'shell', "$nativeCommand extract")
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'pull', $deviceDirectory, $samples)
    Invoke-MediaCommand -Executable $dart -ArgumentList @('tools/media_probe/remux_mpeg.dart', $samples)
    foreach ($sample in @('audio.ts', 'video.ts', 'audio.ps', 'video.ps')) {
        Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'push', "$samples\$sample", "$deviceDirectory/$sample")
    }
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'shell', "$nativeCommand verify")
    Invoke-MediaCommand -Executable $adb -ArgumentList @('-s', $Device, 'pull', "$deviceDirectory/mpeg_native.json", "$samples\mpeg_native.json")
    Invoke-MediaCommand -Executable $dart -ArgumentList @('tools/media_probe/inspect.dart', $samples)
    Invoke-MediaCommand -Executable $flutter -ArgumentList @('test', 'tools/media_probe/import_test.dart',
        "--dart-define=MEDIA_PROBE_SAMPLES=$samples", '--reporter', 'expanded')
    Write-Output "Evidence: $samples\probe_report.json"
    # Keep isolated evidence; never remove app data or existing files.
} finally {
    Pop-Location
}
