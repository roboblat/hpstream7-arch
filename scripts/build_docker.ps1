# ============================================================
# build_docker.ps1
# One-shot Windows builder — produces hpstream7-arch.iso using
# Docker Desktop. No WSL, no Arch install, no VM setup.
#
# Prereq: Docker Desktop installed and running.
# Run from project root:
#   powershell -ExecutionPolicy Bypass -File .\scripts\build_docker.ps1
# ============================================================

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Err($msg)  { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ── resolve project root (parent of scripts/) ──────────────────────
$ProjectRoot = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path (Join-Path $ProjectRoot "Dockerfile.builder"))) {
    Write-Err "Dockerfile.builder not found. Run this from the project root."
    exit 1
}

# ── check Docker ──────────────────────────────────────────────────
try {
    docker version --format '{{.Server.Version}}' | Out-Null
} catch {
    Write-Err "Docker is not running. Start Docker Desktop and try again."
    exit 1
}

# ── build the builder image (cached after first run) ──────────────
Write-Info "Building Docker builder image (first run ~5 min, cached after)..."
docker build -f (Join-Path $ProjectRoot "Dockerfile.builder") `
    -t hpstream7-builder `
    $ProjectRoot
if ($LASTEXITCODE -ne 0) { Write-Err "docker build failed"; exit 1 }

# ── ensure output dir ─────────────────────────────────────────────
$OutDir = Join-Path $ProjectRoot "out"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

# ── run the build ─────────────────────────────────────────────────
Write-Info "Running ISO build (10-20 min depending on download speed)..."
Write-Info "The container is --privileged because archiso needs loop devices."
docker run --rm --privileged `
    -v "${ProjectRoot}:/work" `
    -v "${OutDir}:/out" `
    hpstream7-builder
if ($LASTEXITCODE -ne 0) { Write-Err "ISO build failed"; exit 1 }

# ── show result ───────────────────────────────────────────────────
$iso = Get-ChildItem $OutDir -Filter *.iso | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($iso) {
    $size = [math]::Round($iso.Length / 1MB, 1)
    Write-Host ""
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host " Build complete!" -ForegroundColor Green
    Write-Host " File: $($iso.FullName)"
    Write-Host " Size: $size MB"
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next step — write to USB:"
    Write-Host "  Option A: Rufus/Etcher (DD mode)"
    Write-Host "  Option B: .\scripts\write_usb_windows.ps1 -IsoPath `"$($iso.FullName)`""
} else {
    Write-Err "No ISO found in $OutDir after build."
    exit 1
}
