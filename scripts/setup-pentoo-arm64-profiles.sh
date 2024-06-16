#!/bin/bash
###setup-pentoo-arm64-profiles.sh##

# Define the base directories
PENTOO="/var/db/repos/pentoo/profiles/pentoo"
PENTOO_ARM64_BASE="/var/db/repos/pentoo-arm64/profiles/pentoo"
GENPI64_OVERLAY="/var/db/repos/genpi64"

# Define the use cases and device types
USE_CASES=("base-arm64" "genpi64" "orange5-pi" "orangepi-5-plus" "ampere")
DEVICE_TYPES=("rpi4" "rpi5" "ampere" "m1" "m2" "m3" "m4")
echo "$warnuser"
warnuser="Follow up Setup scripts for other devices will be needed not RPI-64  ie orange5-pi ampere Apple m1 m2 m3 m-etc " 

# Create the Pentoo ARM64 profile directories
sudo mkdir -p "$PENTOO_ARM64_BASE/arch/arm64"
sudo mkdir -p "$PENTOO_ARM64_BASE/base"
sudo mkdir -p "$PENTOO_ARM64_BASE/bleeding"
sudo mkdir -p "$PENTOO_ARM64_BASE/binary"
sudo mkdir -p "$PENTOO_ARM64_BASE/bootstrap"
sudo mkdir -p "$PENTOO_ARM64_BASE/default/linux/arm64"
sudo mkdir -p "$PENTOO_ARM64_BASE/hardened/linux/arm64"

# Copy relevant files from the Pentoo AMD64 profiles
sudo cp -r "$PENTOO/arch/amd64/." "$PENTOO_ARM64_BASE/arch/arm64/"
sudo cp -r "$PENTOO/base/." "$PENTOO_ARM64_BASE/base/"
sudo cp -r "$PENTOO/bleeding/." "$PENTOO_ARM64_BASE/bleeding/"
sudo cp -r "$PENTOO/binary/." "$PENTOO_ARM64_BASE/binary/"
sudo cp -r "$PENTOO/bootstrap/." "$PENTOO_ARM64_BASE/bootstrap/"
sudo cp -r "$PENTOO/default/linux/amd64/." "$PENTOO_ARM64_BASE/default/linux/arm64/"
sudo cp -r "$PENTOO/hardened/linux/amd64/." "$PENTOO_ARM64_BASE/hardened/linux/arm64/"

# Create the device type directories
for DEVICE_TYPE in "${DEVICE_TYPES[@]}"; do
  sudo mkdir -p "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE"
done

# Set up the base Pentoo ARM64 profile
sudo echo "gentoo:default/linux/arm64/17.0" | sudo tee "$PENTOO_ARM64_BASE/base/parent"

# Set up the device type profiles
for DEVICE_TYPE in "${DEVICE_TYPES[@]}"; do
  sudo echo "$PENTOO_ARM64_BASE/base" | sudo tee "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/parent"
  
  # Copy relevant files from the GenPi64 overlay based on the device type
  case $DEVICE_TYPE in
    "rpi4"|"rpi5")
      sudo cp -r "$GENPI64_OVERLAY/profiles/targets/genpi64/." "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/"
      ;;
    "ampere")
      sudo cp -r "$GENPI64_OVERLAY/profiles/targets/genpi64desktop/." "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/"
      ;;
    *)
      # Add any specific customizations for other device types
      ;;
  esac
  
  # Add any device type specific customizations
done

# Symlink the custom Pentoo ARM64 profiles to the Portage profile directory
sudo ln -s "$PENTOO_ARM64_BASE" /etc/portage/profile/pentoo-arm64