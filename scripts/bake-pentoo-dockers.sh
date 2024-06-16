#!/bin/bash

# Enable binhost
export PORTAGE_BINHOST_HEADER_URI="https://github.com/Necrohol/gentoo-binhost/releases/download/${CHOST}"

# Fetch pikernel-build.eclass from the specified URL and move it to the pentoo-overlay/eclass directory
curl -o pikernel-build.eclass https://raw.githubusercontent.com/GenPi64/genpi64-overlay/master/eclass/pikernel-build.eclass
mkdir -p /var/db/repos/pentoo-overlay/eclass
mv pikernel-build.eclass /var/db/repos/pentoo-overlay/eclass

# Set up temporary Portage configuration with USE flags for sys-kernel/pentoo-sources
echo "sys-kernel/pentoo-sources experimental lts" >> /etc/portage/package.use/pentoo

# Define the package groups and their corresponding Dockerfile names
package_groups=(
    "pentoo/pentoo-base"
    "pentoo/pentoo-core"
    "pentoo/pentoo-extra"
    "pentoo/pentoo-fuzzers"
    "pentoo/pentoo-installer"
    "pentoo/pentoo-livecd"
    "pentoo/pentoo-misc"
    "pentoo/pentoo-mobile"
    "pentoo/pentoo-nfc"
    "pentoo-opencl"
    "sys-kernel/pentoo-sources"  # Using USE flags experimental and lts
    "pentoo-proxies"
    "pentoo-radio"
    "pentoo-rce" 
    "pentoo-scanner"
    "pentoo/pentoo-system"
    "pentoo-voip"
    "pentoo-wireless"
    "pentoo/pentoo"
)

# Set the ARCH environment variable to arm64
export ENV ARCH=arm64 

# Build the Docker images for each package group
for package_group in "${package_groups[@]}"; do
    # Define the Dockerfile for the current package group
    dockerfile="Dockerfile.$package_group"

    # Build the Docker image for the current package group
    docker build -f "$dockerfile" -t "pentoo/$package_group:arm64" .

    # Check if the current package group is sys-kernel/pentoo-sources
    if [[ "$package_group" == "sys-kernel/pentoo-sources" ]]; then
        # Add patch-pentoo.sh if the package group is sys-kernel/pentoo-sources
        docker build -f "$dockerfile" -t "pentoo/$package_group:arm64" . \
            --build-arg PATCH_SCRIPT=true
    fi
done

# Optionally, you can add additional customizations or steps here

# Set up the base image for the rest of the builds
cat <<EOF > Dockerfile.pentoo-core-base
# Use a base Gentoo image
ENV ARCH=arm64

FROM gentoo/stage3:arm64-desktop-openrc AS arm64_base

# Enable binhost
ENV PORTAGE_BINHOST_HEADER_URI="https://github.com/Necrohol/gentoo-binhost/releases/download/${CHOST}"

# Add QEMU for cross-architecture emulation
ADD https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/x86_64_qemu-aarch64-static.tar.gz /usr/bin/x64_qemu-aarch64-static

# Update repository and install required packages
RUN emerge --sync && \
    emerge app-eselect/eselect-repository dev-vcs/git dev-python/PyGithub

# Copy the setup script into the container
COPY setup_pentoo.sh /root/setup_pentoo.sh
COPY setup-binhost-build.sh /root/setup-binhost-build.sh

# Make the scripts executable
RUN chmod +x /root/*.sh

# Run the setup script
RUN /root/setup_pentoo.sh

# Install Pentoo core packages
RUN emerge --sync && \
    emerge pentoo-core

# Set the default command to run bash
CMD ["/bin/bash"]
EOF
# enable binhost ? set environmental var 
ENV PORTAGE_BINHOST_HEADER_URI="https://github.com/Necrohol/gentoo-binhost/releases/download/${CHOST}"
# Our local fork. push pull binaries to enhance builds or rebuild and clean in GitHub actions...

# Add QEMU for cross-architecture emulation
ADD https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/x86_64_qemu-aarch64-static.tar.gz /usr/bin/x64_qemu-aarch64-static

# Update repository and install required packages
RUN emerge --sync && \
    emerge app-eselect/eselect-repository dev-vcs/git dev-python/PyGithub

# Copy the setup script into the container
COPY setup_pentoo.sh /root/setup_pentoo.sh

# Copy setup-binhost-build.sh into the container
COPY setup-binhost-build.sh /root/setup-binhost-build.sh

# Make the scripts executable
RUN chmod +x /root/*.sh

# Run the setup script
RUN /root/setup_pentoo.sh

# Install Pentoo core packages
RUN emerge --sync && \
    emerge pentoo-core

# Optionally add more customizations here

# Set the default command to run bash
CMD ["/bin/bash"]
This Dockerfile now includes the COPY setup-binhost-build.sh /root/setup-binhost-build.sh line along with comments. Make sure the setup-binhost-build.sh script is in the same directory as your Dockerfile or provide the correct path if it's in a different location. Also, ensure that setup-binhost-build.sh has executable permissions (chmod +x setup-binhost-build.sh).









"
