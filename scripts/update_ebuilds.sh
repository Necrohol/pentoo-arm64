#!/bin/bash

# This script updates Gentoo ebuilds by adding or modifying the EAPI line and the Gentoo header.
# It also provides an option to update the KEYWORDS line by appending arm64 or ~arm64.
#
# Timeouts have been added to the confirmation prompts, making the script suitable for use in
# automated environments like Docker, GitHub Actions, or manual execution.
#
# Note: This script lacks the heuristics to fully migrate ebuilds from EAPI 5, 6, or 7 to EAPI 8.
# It is designed to update the EAPI line to 8, but it does not handle other changes required
# for a complete migration. Additional manual intervention may be necessary for a successful
# transition to EAPI 8, especially for ebuilds with complex dependencies or USE flag configurations.
#
# Additionally, this script does not handle licensing changes required for EAPI 8 migration.
# Ebuilds using licenses other than the MIT license may require manual updates. For example,
# ebuilds using the GPL license may need to have the LICENSE variable updated from "GPL-2" to
# "|| ( GPL-2 )" to comply with EAPI 8 requirements.
#
# A recursion function has been added to process directories and their subdirectories, enabling
# the script to handle large quantities of ebuild files. This makes it suitable for use in
# automated workflows like GitHub Actions (e.g., ./github/update-headers-action.yml).
#
# This script is licensed under the MIT License.



update_ebuild() {
    local ebuild_file="$1"
    local current_year=$(date +%Y)
    local response=""
    local timeout=10  # Set the timeout in seconds

    # Check if EAPI line is present and prompt for update to EAPI=8
    if grep -q "^EAPI=" "$ebuild_file"; then
        read -r -p "Update EAPI in $ebuild_file? [y/N] " -t "$timeout" response
        response=${response,,}    # Convert response to lowercase
        if [[ "$response" =~ ^(yes|y)$ ]]; then
            sed -i 's/^EAPI=.*/EAPI=8/' "$ebuild_file"
        fi
    else
        read -r -p "Add EAPI=8 to $ebuild_file? [y/N] " -t "$timeout" response
        response=${response,,}    # Convert response to lowercase
        if [[ "$response" =~ ^(yes|y)$ ]]; then
            sed -i '1iEAPI=8\n' "$ebuild_file"
        fi
    fi

    # Add Gentoo header if missing
    local header1="# Copyright 1999-$current_year Gentoo Authors"
    local header2="# Distributed under the terms of the GNU General Public License v2"

    if ! grep -q "$header1" "$ebuild_file" && ! grep -q "$header2" "$ebuild_file"; then
        sed -i "1i$header2\n$header1\n" "$ebuild_file"
    fi
}
update_keywords() {
    local ebuild_file="$1"
    local response=""
    local timeout=10  # Set the timeout in seconds

    # Update KEYWORDS line
    if grep -q "^KEYWORDS=" "$ebuild_file"; then
        if grep -q "amd64" "$ebuild_file"; then
            # If amd64 is present, prompt to append arm64
            read -r -p "Append arm64 to KEYWORDS in $ebuild_file? [y/N] " -t "$timeout" response
            response=${response,,}    # Convert response to lowercase
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                sed -i '/^KEYWORDS=/s/\(amd64\)/\1 arm64/' "$ebuild_file"
            fi
        elif grep -q "~amd64" "$ebuild_file"; then
            # If ~amd64 is present, prompt to append ~arm64
            read -r -p "Append ~arm64 to KEYWORDS in $ebuild_file? [y/N] " -t "$timeout" response
            response=${response,,}    # Convert response to lowercase
            if [[ "$response" =~ ^(yes|y)$ ]]; then
                sed -i '/^KEYWORDS=/s/\(~amd64\)/\1 ~arm64/' "$ebuild_file"
            fi
        fi
    fi
}
}# Recursive function to process directories
process_directory() {
    local dir="$1"
    
    # Loop through files and directories in the current directory
    for entry in "$dir"/*; do
        if [ -d "$entry" ]; then
            # If it's a directory, call the function recursively
            process_directory "$entry"
        elif [ -f "$entry" ] && [[ "$entry" == *.ebuild ]]; then
            # If it's an ebuild file, process it
            echo "Updating $entry"
            update_ebuild "$entry"
            update_keywords "$entry"
        fi
    done
}

# Check if at least one argument is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <directory> [<directory> ...]"
    exit 1
fi

# Loop through all provided directories and process them
for dir in "$@"; do
    if [ -d "$dir" ]; then
        process_directory "$dir"
    else
        echo "Not a directory: $dir"
    fi
done