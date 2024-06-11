#!/bin/bash

# Enable the Pentoo repository
echo "Enabling the Pentoo repository..."
eselect repository enable pentoo

# Add keywording for ~arm64 for Pentoo repository
echo "Adding keywording for ~arm64 for Pentoo repository..."
mkdir -p /etc/portage/package.accept_keywords
echo "*/*::pentoo ~arm64" >> /etc/portage/package.accept_keywords/pentoo_repo
## pentoo-arm64 https://github.com/Necrohol/pentoo-arm64 "underlay" 
echo "*/*::pentoo-arm64 ~arm64" >> /etc/portage/package.accept_keywords/pentoo-arm64_repo

# Add keywording for ~arm64 for Gentoo repository
echo "Adding keywording for ~arm64 for Gentoo repository..."
echo "*/*::gentoo ~arm64" >> /etc/portage/package.accept_keywords/gentoo_repo

echo "Setup complete."
