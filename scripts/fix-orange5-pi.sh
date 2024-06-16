#!/bin/bash
###fix-orange5-pi.sh##

# Define the base directories
PENTOO="/var/db/repos/pentoo/profiles/pentoo"
PENTOO_ARM64_BASE="/var/db/repos/pentoo-arm64/profiles/pentoo"
GENPI64_OVERLAY="/var/db/repos/genpi64"

# Define the use cases and device types
USE_CASES=("base-arm64" "genpi64" "orange5-pi" "orangepi-5-plus" "ampere")
DEVICE_TYPES=("rpi4" "rpi5" "orange5-pi" "orangepi-5-plus" "ampere" "m1" "m2" "m3" "m4")

# Function to update make.defaults for Orange Pi 5 and Orange Pi 5 Plus
update_orange5_make_defaults() {
  local make_defaults_file="$1"
  
  sed -i '/COMMON_FLAGS=/d' "$make_defaults_file"
  sed -i '/RUSTFLAGS=/d' "$make_defaults_file"
  sed -i '/MAKEOPTS=/d' "$make_defaults_file"
  sed -i '/VIDEO_CARDS=/d' "$make_defaults_file"
  sed -i '/CPU_FLAGS_ARM=/d' "$make_defaults_file"
  sed -i '/EMERGE_DEFAULT_OPTS=/d' "$make_defaults_file"
  
  echo 'COMMON_FLAGS="-O2 -pipe -march=armv8.4-a+crc+crypto -mtune=cortex-a76"' | sudo tee -a "$make_defaults_file"
  echo 'RUSTFLAGS="-C target-cpu=native"' | sudo tee -a "$make_defaults_file"
  echo 'MAKEOPTS="-j8"' | sudo tee -a "$make_defaults_file"
  echo 'VIDEO_CARDS="panfrost lima mali"' | sudo tee -a "$make_defaults_file"
  echo 'CPU_FLAGS_ARM="aes32 crc32 sha2 sha3 sm3 sm4 asimddp atomics"' | sudo tee -a "$make_defaults_file"
  echo 'EMERGE_DEFAULT_OPTS="--jobs=8 --load-average=8 --keep-going --with-bdeps=y"' | sudo tee -a "$make_defaults_file"
}

# Update make.defaults for Orange Pi 5 and Orange Pi 5 Plus
for DEVICE_TYPE in "orange5-pi" "orangepi-5-plus"; do
  make_defaults_file="$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/make.defaults"
  
  if [[ -f "$make_defaults_file" ]]; then
    update_orange5_make_defaults "$make_defaults_file"
    echo "Updated $make_defaults_file for $DEVICE_TYPE"
  else
    echo "File $make_defaults_file not found for $DEVICE_TYPE"
  fi
done

#make.conf
# Compiler flags
COMMON_FLAGS="-O2 -pipe -march=armv8.4-a+crc+crypto -mtune=cortex-a76"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

# Number of parallel build jobs
#MAKEOPTS="-j8"

# CPU_FLAGS_ARM
#CPU_FLAGS_ARM="aes32 crc32 sha2 sha3 sm3 sm4 asimddp atomics"

# USE flags
#USE="arm64 elogind -consolekit -systemd"

# Firmware
#USE_EXPANDED="FIRMWARE=rk3588"

# Video cards
#IDEO_CARDS="panfrost lima"

# Input devices
#INPUT_DEVICES="libinput"

# Kernel target
#ERNEL_TARGET="Image"

# Emerge options
#EMERGE_DEFAULT_OPTS="--jobs=8 --load-average=8 --keep-going --with-bdeps=y"

# License
#ACCEPT_LICENSE="* -@EULA"