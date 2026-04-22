# ============================================================
# write_usb_windows.ps1
# Copy the HP Stream 7 Arch ISO contents to a FAT32 USB drive
# using only Windows built-in tools (no Rufus / Etcher needed).
#
# Works because the Stream 7 boots via UEFI — any FAT32 stick
# with /EFI/BOOT/BOOTIA32.EFI will boot.
#
# Run as Administrator:
#   powershell -ExecutionPolicy Bypass -File .\write_usb_windows.ps1
# ============================================================

#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$IsoPath,

    [Parameter(Mandatory=$false)]
    [string]$DriveLetter
)

$ErrorActionPreference = "Stop"

function Write-Info($msg) { Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "[ERROR] $msg" -ForegroundColor Red }

# ── sanity ─────────────────────────────────────────────────────────
if (-not (Test-Path $IsoPath)) { Write-Err "ISO not found: $IsoPath"; exit 1 }

# ── pick a USB drive if not given ─────────────────────────────────
if (-not $DriveLetter) {
    $usbDrives = Get-Disk | Where-Object BusType -eq 'USB'
    if (-not $usbDrives) { Write-Err "No USB drives detected."; exit 1 }
    Write-Host ""
    Write-Host "USB drives found:" -ForegroundColor Cyan
    $usbDrives | ForEach-Object {
        $size = [math]::Round($_.Size / 1GB, 1)
        Write-Host ("  Disk {0}  {1,6} GB  {2}" -f $_.Number, $size, $_.FriendlyName)
    }
    Write-Host ""
    $diskNum = Read-Host "Enter disk number to erase & write"
    $disk = $usbDrives | Where-Object Number -eq [int]$diskNum
    if (-not $disk) { Write-Err "Invalid disk number."; exit 1 }
} else {
    $vol = Get-Volume -DriveLetter $DriveLetter.TrimEnd(':')
    $disk = Get-Partition -DriveLetter $DriveLetter.TrimEnd(':') | Get-Disk
}

# ── find the label the ISO expects ────────────────────────────────
$isoLabel = "HPSTREAM7_$(Get-Date -Format 'yyyyMM')"
Write-Info "Using label: $isoLabel"

# ── confirm destruction ───────────────────────────────────────────
Write-Warn "About to ERASE: Disk $($disk.Number) — $($disk.FriendlyName) ($([math]::Round($disk.Size/1GB,1)) GB)"
$confirm = Read-Host "Type YES to proceed"
if ($confirm -ne "YES") { Write-Info "Aborted."; exit 0 }

# ── wipe & partition via diskpart ─────────────────────────────────
Write-Info "Partitioning (diskpart)..."
$diskpartScript = @"
select disk $($disk.Number)
clean
create partition primary
active
format fs=fat32 quick label=$isoLabel
assign
exit
"@
$tmp = [System.IO.Path]::GetTempFileName()
Set-Content -Path $tmp -Value $diskpartScript -Encoding ascii
diskpart /s $tmp | Out-Null
Remove-Item $tmp

Start-Sleep -Seconds 2

# ── find the new drive letter ─────────────────────────────────────
$newVol = Get-Partition -DiskNumber $disk.Number | Where-Object DriveLetter | Select-Object -First 1
if (-not $newVol.DriveLetter) { Write-Err "No drive letter assigned after format."; exit 1 }
$usbRoot = "$($newVol.DriveLetter):\"
Write-Info "USB is now at $usbRoot"

# ── mount the ISO ─────────────────────────────────────────────────
Write-Info "Mounting ISO..."
$mount = Mount-DiskImage -ImagePath (Resolve-Path $IsoPath) -PassThru
$isoDrive = ($mount | Get-Volume).DriveLetter
if (-not $isoDrive) { Write-Err "Failed to mount ISO."; exit 1 }
$isoRoot = "${isoDrive}:\"
Write-Info "ISO mounted at $isoRoot"

# ── copy everything ───────────────────────────────────────────────
Write-Info "Copying files (this takes 3-10 minutes)..."
# robocopy: /E all subdirs, /NFL /NDL quieter, /R:1 /W:1 don't hang on errors
robocopy $isoRoot $usbRoot /E /R:1 /W:1 /NFL /NDL | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Warn "robocopy reported errors (exit $LASTEXITCODE)" }

# ── unmount ISO ───────────────────────────────────────────────────
Dismount-DiskImage -ImagePath (Resolve-Path $IsoPath) | Out-Null

# ── verify the critical boot file ─────────────────────────────────
$bootia32 = Join-Path $usbRoot "EFI\BOOT\BOOTIA32.EFI"
if (Test-Path $bootia32) {
    Write-Info "BOOTIA32.EFI present — UEFI 32-bit boot should work."
} else {
    Write-Warn "BOOTIA32.EFI missing — the Stream 7 may not boot this stick!"
    Write-Warn "The ISO was probably built without the ia32 injection step."
}

Write-Host ""
Write-Info "Done! Safely eject the drive and plug it into the Stream 7 via OTG."
Write-Host ""
