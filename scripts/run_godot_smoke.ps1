param(
    [string]$GodotPath = "",
    [int]$TimeoutSeconds = 120
)

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ArtifactsDirectory = Join-Path $ProjectRoot "test-results"
$ImportLog = Join-Path $ArtifactsDirectory "godot-import.log"
$SmokeLog = Join-Path $ArtifactsDirectory "godot-smoke.log"

New-Item -ItemType Directory -Force -Path $ArtifactsDirectory | Out-Null

if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $Candidates = @(
        "godot",
        "godot4",
        "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe",
        (Join-Path $ProjectRoot "Godot_v4.7-stable_win64.exe")
    )
    foreach ($Candidate in $Candidates) {
        if (Get-Command $Candidate -ErrorAction SilentlyContinue) {
            $GodotPath = (Get-Command $Candidate).Source
            break
        }
        if (Test-Path $Candidate) {
            $GodotPath = $Candidate
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotPath) -or -not (Test-Path $GodotPath)) {
    throw "No encontré Godot. Usa -GodotPath con la ruta de Godot 4.7."
}

function Invoke-GodotChecked {
    param(
        [string[]]$Arguments,
        [string]$LogPath,
        [string]$StageName
    )

    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }

    $Process = Start-Process -FilePath $GodotPath -ArgumentList $Arguments -PassThru -NoNewWindow
    if (-not $Process.WaitForExit($TimeoutSeconds * 1000)) {
        $Process.Kill()
        throw "$StageName excedió $TimeoutSeconds segundos. Revisa $LogPath"
    }

    $LogContent = if (Test-Path $LogPath) {
        Get-Content $LogPath -Raw
    } else {
        ""
    }

    $FatalPattern = "(?im)^\s*(SCRIPT ERROR|ERROR):|Parse Error|Failed to load script"
    if ($Process.ExitCode -ne 0 -or $LogContent -match $FatalPattern) {
        if (-not [string]::IsNullOrWhiteSpace($LogContent)) {
            Write-Host $LogContent
        }
        throw "$StageName falló con código $($Process.ExitCode). Revisa $LogPath"
    }
}

Write-Host "1/4 Verificando contratos de simulación..."
$PythonCommand = Get-Command "python" -ErrorAction SilentlyContinue
if ($null -eq $PythonCommand) {
    throw "No encontré Python para ejecutar los contratos y el verificador de ámbitos."
}
& $PythonCommand.Source -m unittest discover -s (Join-Path $ProjectRoot "tests") -p "test_*contracts.py"
if ($LASTEXITCODE -ne 0) {
    throw "Fallaron los contratos de simulación."
}

Write-Host "2/4 Verificando ámbitos GDScript..."
& $PythonCommand.Source (Join-Path $ProjectRoot "check_gdscript.py") (Join-Path $ProjectRoot "df_mode") "--strict"
if ($LASTEXITCODE -ne 0) {
    throw "El verificador encontró variables locales duplicadas."
}

Write-Host "3/4 Importando y validando el proyecto..."
Invoke-GodotChecked `
    -Arguments @("--headless", "--path", $ProjectRoot, "--editor", "--quit", "--log-file", $ImportLog) `
    -LogPath $ImportLog `
    -StageName "Importación"

Write-Host "4/4 Ejecutando prueba nativa de arranque..."
Invoke-GodotChecked `
    -Arguments @("--headless", "--path", $ProjectRoot, "--script", "res://tests/runtime_smoke.gd", "--log-file", $SmokeLog) `
    -LogPath $SmokeLog `
    -StageName "Prueba de arranque"

Write-Host "OK: Bigli cargó sus scripts y escena principal sin errores detectados."
Write-Host "Logs: $ArtifactsDirectory"
