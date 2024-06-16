#!/bin/bash
###fix-ampere.sh##

# Define the base directories
PENTOO="/var/db/repos/pentoo/profiles/pentoo"
PENTOO_ARM64_BASE="/var/db/repos/pentoo-arm64/profiles/pentoo"
GENPI64_OVERLAY="/var/db/repos/genpi64"

# Define the use cases and device types
USE_CASES=("base-arm64" "genpi64" "orange5-pi" "orangepi-5-plus" "ampere")
DEVICE_TYPES=("rpi4" "rpi5" "orange5-pi" "orangepi-5-plus" "ampere" "m1" "m2" "m3" "m4")

# Function to update make.defaults for Ampere
update_ampere_make_defaults() {
  local make_defaults_file="$1"
  local cpu_cores="$2"
  
  sed -i '/COMMON_FLAGS=/d' "$make_defaults_file"
  sed -i '/RUSTFLAGS=/d' "$make_defaults_file"
  sed -i '/MAKEOPTS=/d' "$make_defaults_file"
  sed -i '/VIDEO_CARDS=/d' "$make_defaults_file"
  sed -i '/EMERGE_DEFAULT_OPTS=/d' "$make_defaults_file"
  
  echo 'COMMON_FLAGS="-O2 -pipe -march=armv8.2-a+crypto -mcpu=neoverse-n1"' | sudo tee -a "$make_defaults_file"
  echo 'RUSTFLAGS="-C target-cpu=native"' | sudo tee -a "$make_defaults_file"
  echo "MAKEOPTS=\"-j$((cpu_cores + 1))\"" | sudo tee -a "$make_defaults_file"
  echo 'VIDEO_CARDS="nvidia radeon nouveau"' | sudo tee -a "$make_defaults_file"
  echo "EMERGE_DEFAULT_OPTS=\"--jobs=$cpu_cores --load-average=$cpu_cores --keep-going --with-bdeps=y\"" | sudo tee -a "$make_defaults_file"
}

# Update make.defaults for Ampere
for DEVICE_TYPE in "ampere"; do
  make_defaults_file="$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/make.defaults"
  
  if [[ -f "$make_defaults_file" ]]; then
    cpu_cores=$(nproc)
    
    update_ampere_make_defaults "$make_defaults_file" "$cpu_cores"
    echo "Updated $make_defaults_file for $DEVICE_TYPE with $cpu_cores CPU cores"
  else
    echo "File $make_defaults_file not found for $DEVICE_TYPE"
  fi
done