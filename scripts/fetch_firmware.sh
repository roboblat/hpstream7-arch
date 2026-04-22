#!/usr/bin/env bash
# Download the Silead MSSL1680 touchscreen firmware blob.
# Must be run on a machine with internet access before building the ISO.
# The firmware is NOT redistributable in linux-firmware; it lives in a
# community repo: https://github.com/onitake/gsl-firmware
set -euo pipefail

DEST="$(dirname "$0")/../airootfs/usr/lib/firmware/silead"
FW_URL="https://raw.githubusercontent.com/onitake/gsl-firmware/master/firmware/hp/stream7/mssl1680.fw"

mkdir -p "$DEST"
echo "Downloading Silead MSSL1680 firmware ..."
wget -q --show-progress -O "$DEST/mssl1680.fw" "$FW_URL"
echo "Saved to $DEST/mssl1680.fw"
