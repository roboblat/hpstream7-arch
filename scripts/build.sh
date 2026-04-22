#!/usr/bin/env bash
# ============================================================
# Build the HP Stream 7 Arch Linux ISO using archiso.
# Must run on an Arch Linux host as root (or with sudo).
# ============================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$(realpath "$SCRIPT_DIR/..")"
OUT_DIR="$PROFILE_DIR/out"
WORK_DIR="/tmp/hpstream7-archiso-work"

RED='\033[0;31m'; GRN='\033[0;32m'; YEL='\033[1;33m'; NC='\033[0m'
info()  { echo -e "${GRN}[BUILD]${NC} $*"; }
warn()  { echo -e "${YEL}[WARN]${NC}  $*"; }
die()   { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

# ── preflight ─────────────────────────────────────────────────────────────────
[[ $EUID -eq 0 ]] || die "Run as root: sudo ./scripts/build.sh"
command -v mkarchiso &>/dev/null || die "archiso not installed. Run: pacman -S archiso"

# ── generate vaporwave wallpaper ──────────────────────────────────────────────
if ! [[ -f "$PROFILE_DIR/airootfs/usr/share/backgrounds/vaporwave/sunset.png" ]]; then
    if command -v magick &>/dev/null; then
        info "Generating vaporwave wallpaper ..."
        bash "$SCRIPT_DIR/gen_wallpaper.sh" || warn "Wallpaper generation failed — shipping without"
    else
        warn "ImageMagick not installed — skipping wallpaper generation"
    fi
fi

# ── copy package list to expected archiso location ────────────────────────────
info "Preparing package list ..."
cp "$PROFILE_DIR/packages/packages.x86_64" "$PROFILE_DIR/packages.x86_64"

# ── build ─────────────────────────────────────────────────────────────────────
info "Cleaning previous work directory ..."
rm -rf "$WORK_DIR"
mkdir -p "$OUT_DIR"

info "Running mkarchiso ..."
mkarchiso \
    -v \
    -w "$WORK_DIR" \
    -o "$OUT_DIR" \
    "$PROFILE_DIR"

# ── find ISO ──────────────────────────────────────────────────────────────────
# Note: uefi-ia32.grub.esp in profiledef.sh already makes mkarchiso build
# and embed BOOTIA32.EFI with correct label substitution. No post-processing needed.
ISO="$(ls -t "$OUT_DIR"/*.iso | head -1)"
[[ -f "$ISO" ]] || die "ISO not found in $OUT_DIR"

# ── summary ───────────────────────────────────────────────────────────────────
ISO_SIZE=$(du -sh "$ISO" | cut -f1)
info "Build complete!"
echo ""
echo "  ISO : $ISO"
echo "  Size: $ISO_SIZE"
echo ""
echo "Write to USB:"
echo "  sudo dd if=\"$ISO\" of=/dev/sdX bs=4M status=progress oflag=sync"
echo ""
echo "Or boot with QEMU to test:"
echo "  qemu-system-x86_64 -m 1G -enable-kvm -bios /usr/share/ovmf/x64/OVMF.fd \\"
echo "    -cdrom \"$ISO\" -boot d"
