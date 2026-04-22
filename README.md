# HP Stream 7 — Arch Linux Custom ISO

A tailored Arch Linux live/install ISO for the **HP Stream 7** (5th-gen, Intel Atom Z3735G Bay Trail).

## Hardware profile

| Component | Chip / Details |
|-----------|---------------|
| CPU | Intel Atom Z3735G (Bay Trail-T, x86_64, 64-bit OS, 32-bit UEFI) |
| RAM | 1 GB LPDDR3 |
| Storage | 32 GB eMMC (mmcblk0) |
| Display | 7" 1280×800 IPS |
| Touchscreen | Silead MSSL1680 / Goodix GT9xx (I²C-HID) |
| WiFi/BT | Realtek RTL8723BS (SDIO) |
| Audio | Intel Baytrail SST |
| Camera | OV5648 (MIPI CSI) |
| Ports | micro-USB OTG, micro-HDMI, micro-SD, 3.5 mm |
| UEFI | 32-bit IA32 EFI (on 64-bit CPU) |

## Key challenges solved

- **32-bit UEFI** — ships `bootia32.efi` (GRUB ia32) alongside the normal 64-bit GRUB
- **RTL8723BS** — out-of-tree SDIO Wi-Fi driver compiled or loaded via DKMS
- **Touchscreen** — Silead firmware blob + `goodix` kernel module
- **eMMC boot** — `mmc_block` built into initramfs; correct `/dev/mmcblk0` partition layout
- **Low RAM** — zram swap enabled by default; ZSTD compression throughout

## Building the ISO — three ways

### Option 1: Windows / Mac via Docker (easiest)

Requires only [Docker Desktop](https://www.docker.com/products/docker-desktop/).

```powershell
# from project root, in admin PowerShell
.\scripts\build_docker.ps1
```

Output: `out/hpstream7-arch-YYYY.MM.DD.iso`

### Option 2: GitHub Actions (no local tools at all)

Push this repo to GitHub, go to the **Actions** tab, run "Build HP Stream 7 ISO".
Download the ISO from the workflow artifacts when it finishes (~15 min).

### Option 3: Native Arch Linux

```bash
sudo pacman -S archiso grub dosfstools mtools libisoburn imagemagick
./scripts/fetch_firmware.sh
./scripts/gen_wallpaper.sh
sudo ./scripts/build.sh
```

## Writing to USB

```bash
sudo dd if=out/hpstream7-arch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## First boot / installation

After booting the live environment run:

```bash
sudo hpstream7-install
```

The guided installer partitions the eMMC, installs base packages, installs
the 32-bit GRUB EFI bootloader, and copies device-specific config.

## Directory layout

```
arch/
├── airootfs/           mirror of / inside the ISO
│   ├── etc/            device config files
│   └── usr/local/bin/  helper scripts (hpstream7-install, etc.)
├── efiboot/            EFI system partition content
├── grub/               GRUB config templates
├── packages/           package lists
├── hooks/              archiso hooks
├── scripts/            build & helper scripts
└── profiledef.sh       archiso profile definition
```
