#!/bin/bash
###setup-pentoo-arm64-profiles.sh##

# Define the base directories
PENTOO="/var/db/repos/pentoo/profiles/pentoo"
PENTOO_ARM64_BASE="/var/db/repos/pentoo-arm64/profiles/pentoo"
GENPI64_OVERLAY="/var/db/repos/genpi64"
SYSTEMS_DIR="/var/db/repos/pentoo/profiles/systems"

# Define the use cases and device types
USE_CASES=("base-arm64" "genpi64" "orange5-pi" "orangepi-5-plus" "ampere")
DEVICE_TYPES=("rpi4" "rpi5" "ampere" "m1" "m2" "m3" "m4")

warnuser="Follow up Setup scripts for other devices will be needed not RPI-64  ie orange5-pi ampere Apple m1 m2 m3 m-etc"
echo "$warnuser"

# Create the Pentoo ARM64 profile directories
mkdir -p "$PENTOO_ARM64_BASE/arch/arm64"
mkdir -p "$PENTOO_ARM64_BASE/base"
mkdir -p "$PENTOO_ARM64_BASE/bleeding"
mkdir -p "$PENTOO_ARM64_BASE/binary"
mkdir -p "$PENTOO_ARM64_BASE/bootstrap"
mkdir -p "$PENTOO_ARM64_BASE/default/linux/arm64"
mkdir -p "$PENTOO_ARM64_BASE/default/linux/arm64/23.0/hardened"
mkdir -p "$PENTOO_ARM64_BASE/default/linux/arm64/23.0/desktop"
mkdir -p "$PENTOO_ARM64_BASE/hardened/linux/arm64"
mkdir -p "$PENTOO_ARM64_BASE/systems"

# Copy relevant files from the Pentoo AMD64 profiles
cp -rT "$PENTOO/arch/amd64" "$PENTOO_ARM64_BASE/arch/arm64"
cp -rT "$PENTOO/base" "$PENTOO_ARM64_BASE/base"
cp -rT "$PENTOO/bleeding" "$PENTOO_ARM64_BASE/bleeding"
cp -rT "$PENTOO/binary" "$PENTOO_ARM64_BASE/binary"
cp -rT "$PENTOO/bootstrap" "$PENTOO_ARM64_BASE/bootstrap"
cp -rT "$PENTOO/default/linux/amd64" "$PENTOO_ARM64_BASE/default/linux/arm64"
cp -rT "$PENTOO/hardened/linux/amd64" "$PENTOO_ARM64_BASE/hardened/linux/arm64"

# Copy the systems profiles
cp -rT "$SYSTEMS_DIR" "$PENTOO_ARM64_BASE/systems"

# Create the Nu-arm64, default-arm64, and hot_default-arm64 profiles
mkdir -p "$PENTOO_ARM64_BASE/systems/Nu-arm64"
mkdir -p "$PENTOO_ARM64_BASE/systems/default-arm64"
mkdir -p "$PENTOO_ARM64_BASE/systems/hot_default-arm64"

# Set the parent profiles for these new profiles
echo -e "pentoo:pentoo/hardened/linux/amd64_r1\npentoo:pentoo/zero-system" > "$PENTOO_ARM64_BASE/systems/Nu-arm64/parent"
echo -e "pentoo:pentoo/hardened/linux/amd64_r1/binary\npentoo:pentoo/zero-system" > "$PENTOO_ARM64_BASE/systems/default-arm64/parent"
echo -e "pentoo:pentoo/hardened/linux/amd64_r1\npentoo:pentoo/zero-system" > "$PENTOO_ARM64_BASE/systems/hot_default-arm64/parent"

# Set the parent profiles for default/linux/arm64/23.0/hardened and default/linux/arm64/23.0/desktop
echo -e "pentoo:pentoo/hardened/linux/amd64_r1\npentoo:pentoo/zero-system" > "$PENTOO_ARM64_BASE/default/linux/arm64/23.0/hardened/parent"
echo -e "pentoo:pentoo/hardened/linux/amd64_r1/binary\npentoo:pentoo/zero-system" > "$PENTOO_ARM64_BASE/default/linux/arm64/23.0/desktop/parent"

# Create the device type directories
for DEVICE_TYPE in "${DEVICE_TYPES[@]}"; do
   mkdir -p "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE"
done

# Set up the base Pentoo ARM64 profile
echo "gentoo:default/linux/arm64/17.0" | tee "$PENTOO_ARM64_BASE/base/parent"

# Set up the device type profiles
for DEVICE_TYPE in "${DEVICE_TYPES[@]}"; do
   echo "$PENTOO_ARM64_BASE/base" | tee "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE/parent"
  
   # Copy relevant files from the GenPi64 overlay based on the device type
   case $DEVICE_TYPE in
      "rpi4"|"rpi5")
         cp -rT "$GENPI64_OVERLAY/profiles/targets/genpi64" "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE"
         ;;
      "ampere")
         cp -rT "$GENPI64_OVERLAY/profiles/targets/genpi64desktop" "$PENTOO_ARM64_BASE/targets/$DEVICE_TYPE"
         ;;
      *)
         # Add any specific customizations for other device types
         ;;
   esac
  
   # Add any device type specific customizations
done

# Symlink the custom Pentoo ARM64 profiles to the Portage profile directory
ln -sfn "$PENTOO_ARM64_BASE" /etc/portage/profile/pentoo-arm64

echo "Setup complete. Follow up setup scripts for other devices (not RPI-64) like orange5-pi, ampere, Apple m1, m2, m3, etc., are needed."

# Placeholder for setting up a binhost
# Note: This part requires additional setup outside of this script. Ensure a binary host is configured and available for ARM64 before enabling the binary profile.
