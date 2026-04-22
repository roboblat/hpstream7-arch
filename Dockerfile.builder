# ============================================================
# Dockerfile.builder — builds the HP Stream 7 Arch Linux ISO
# inside an Arch container so Windows/Mac users don't need a
# native Arch install.
#
# Usage (from project root):
#   docker build -f Dockerfile.builder -t hpstream7-builder .
#   docker run --rm --privileged \
#     -v "${PWD}:/work" -v "${PWD}/out:/out" \
#     hpstream7-builder
#
# Requires: --privileged (archiso mounts loop devices internally)
# ============================================================

FROM archlinux:latest

# ── update + install build deps ────────────────────────────────────
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        archiso \
        grub \
        dosfstools \
        mtools \
        libisoburn \
        squashfs-tools \
        arch-install-scripts \
        imagemagick \
        wget \
        git \
        sudo && \
    # clear pacman cache to keep image small
    pacman -Scc --noconfirm

# ── entrypoint that runs the project's build.sh ────────────────────
WORKDIR /work
ENTRYPOINT ["/bin/bash", "-c", "\
    set -e && \
    echo '=== HP Stream 7 ISO builder ===' && \
    echo 'Fetching touchscreen firmware...' && \
    bash /work/scripts/fetch_firmware.sh || echo 'firmware fetch failed (continuing)' && \
    echo 'Generating vaporwave wallpaper...' && \
    bash /work/scripts/gen_wallpaper.sh || echo 'wallpaper gen failed (continuing)' && \
    echo 'Building ISO with mkarchiso...' && \
    bash /work/scripts/build.sh && \
    echo 'Copying ISO to /out...' && \
    mkdir -p /out && \
    cp /work/out/*.iso /out/ && \
    chmod 644 /out/*.iso && \
    echo '=== Build complete ===' && \
    ls -lh /out/ \
"]
