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
command -v grub-install &>/dev/null || die "grub not installed. Run: pacman -S grub"

# The ia32 GRUB EFI target requires grub's i386-efi platform files.
# On most Arch hosts these are in /usr/lib/grub/i386-efi (part of grub package).
[[ -d /usr/lib/grub/i386-efi ]] || \
    die "/usr/lib/grub/i386-efi missing. The grub package should provide it."

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

# ── ia32 GRUB EFI injection ───────────────────────────────────────────────────
# mkarchiso only writes grubx64.efi by default.
# The HP Stream 7 needs bootia32.efi (32-bit UEFI), so we inject it here
# by mounting the ESP image from the freshly built ISO and adding the file.
ISO="$(ls -t "$OUT_DIR"/*.iso | head -1)"
[[ -f "$ISO" ]] || die "ISO not found in $OUT_DIR"

info "Injecting 32-bit GRUB EFI into $ISO ..."
MOUNTDIR=$(mktemp -d)
# xorriso can patch an ISO in place
xorriso -osirrox on \
    -indev "$ISO" -outdev "$ISO" \
    -boot_image any replay \
    -find / -name "EFI" -exec echo "EFI dir found" \; \
    -- \
    2>/dev/null || true

# Alternative: rebuild the ESP from scratch and embed bootia32.efi
ESP_IMG=$(mktemp)
# Extract the existing ESP image
xorriso -osirrox on -indev "$ISO" \
    -extract /EFI/BOOT/BOOTx64.efi /dev/null 2>/dev/null || true

# Build bootia32.efi
GRUB_CFG=$(mktemp)
cat > "$GRUB_CFG" << 'GCFG'
search --no-floppy --set=root --label %ARCHISO_LABEL%
set prefix=($root)/boot/grub
source $prefix/grub.cfg
GCFG
grub-mkimage \
    --format=i386-efi \
    --output="$MOUNTDIR/bootia32.efi" \
    --config="$GRUB_CFG" \
    --prefix="/EFI/BOOT" \
    part_gpt part_msdos fat iso9660 udf \
    ext2 btrfs f2fs \
    linux normal chain boot configfile \
    loopback ls search search_fs_uuid \
    search_fs_file search_label \
    help echo test \
    all_video gfxterm gfxmenu \
    font png

# Inject bootia32.efi into the ISO
xorriso -dev "$ISO" \
    -map "$MOUNTDIR/bootia32.efi" "/EFI/BOOT/BOOTIA32.EFI" \
    -commit 2>/dev/null || \
warn "xorriso inject failed — BOOTIA32.EFI was not added. \
You may need to add it manually with osirrox."

rm -rf "$MOUNTDIR" "$GRUB_CFG" "$ESP_IMG"

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
