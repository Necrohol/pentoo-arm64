#!/bin/bash
# patch-pentoo-sources.sh
# Define the path to the ebuild file
# Bake an RPI4/5 kernel of pentoo while pentoo sources bakes...  in docker.. 
ebuild_dir="/var/db/repos/pentoo-overlay/sys-kernel/pentoo-sources"

# Fetch pikernel-build.eclass from the specified URL and move it to the pentoo-overlay/eclass directory
curl -o /var/db/repos/pentoo-overlay/eclass/pikernel-build.eclass https://raw.githubusercontent.com/GenPi64/genpi64-overlay/master/eclass/pikernel-build.eclass

# Set up temporary Portage configuration with USE flags for sys-kernel/pentoo-sources
echo "sys-kernel/pentoo-sources experimental lts" >> /etc/portage/package.use/pentoo

# Loop over each ebuild file in the directory
for ebuild_file in "$ebuild_dir"/*.ebuild; do
    # Use sed to append the lines to the end of each file
    sed -i '/^inherit /a\
    inherit kernel-2 \
    detect_version \
    detect_arch \
    pikernel-build' "$ebuild_file"
done

# Make the script executable
chmod +x patch-pentoo-sources.sh