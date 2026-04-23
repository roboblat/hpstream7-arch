#!/usr/bin/env bash
# archiso profile definition for HP Stream 7

iso_name="hpstream7-arch"
iso_label="HPSTREAM7_$(date +%Y%m)"
iso_publisher="HP Stream 7 Arch Project"
iso_application="Arch Linux for HP Stream 7"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
bootmodes=(
    'uefi-ia32.grub.esp'   # 32-bit UEFI — this tablet NEEDS this one
    'uefi-x64.grub.esp'    # 64-bit UEFI (for other machines)
    # Stream 7 has no legacy BIOS, so we skip syslinux entirely.
)
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '3')
file_permissions=(
    ["/root"]="0:0:750"
    ["/root/.zshrc"]="0:0:644"
    ["/usr/local/bin/hpstream7-install"]="0:0:755"
    ["/usr/local/bin/hpstream7-postinstall"]="0:0:755"
    ["/usr/local/bin/hpstream7-rotate"]="0:0:755"
    ["/usr/local/bin/fix-wifi"]="0:0:755"
    ["/usr/local/bin/fix-touch"]="0:0:755"
    ["/usr/local/bin/fix-bluetooth"]="0:0:755"
    ["/etc/skel/.config/openbox/autostart"]="0:0:755"
)
