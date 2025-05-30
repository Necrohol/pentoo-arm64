# Copyright 2020-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: pikernel-build.eclass
# @MAINTAINER:
# GenPi64 Project ( https://github.com/GenPi64 )
# @SUPPORTED_EAPIS: 7
# @BLURB: Build mechanics for Distribution Kernels for Raspberry Pi
# @DESCRIPTION:
# This eclass provides the logic to build a Distribution Kernel for
# Raspberry Pis from source and install it.  Post-install and test
# logic is inherited  from kernel-install.eclass.
#
# The ebuild must take care of unpacking the kernel sources, copying
# an appropriate .config into them (e.g. in src_prepare()) and setting
# correct S.  The eclass takes care of respecting savedconfig, building
# the kernel and installing it along with its modules and subset
# of sources needed to build external modules.
#
# Based off / inherits from kernel-build.eclass by Michał Górny <mgorny@gentoo.org>

inherit kernel-build

IUSE="bcmrpi bcm2709 bcmrpi3 +bcm2711 -initramfs +llvm clang lto"
REQUIRED_USE="|| ( bcmrpi bcm2709 bcmrpi3 bcm2711 )
	clang? ( llvm )
	lto? ( clang )"

SLOT="0"

# @FUNCTION: pikernel-build_get_cross_compile_vars
# @DESCRIPTION:
# Set up cross-compilation variables based on host and target architecture
pikernel-build_get_cross_compile_vars() {
	local target_arch="${1}"
	local host_arch="$(uname -m)"
	
	# Reset variables
	unset CROSS_COMPILE ARCH LLVM CC LD AR NM OBJCOPY OBJDUMP STRIP
	
	# Determine target kernel architecture
	case "${target_arch}" in
		bcmrpi)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		bcm2709|bcmrpi3|bcm2711)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		orangepi5|orangepi5plus)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		rpizero)
			ARCH="arm"
			KERNEL_ARCH="arm"
			;;
		odroidxu4)
			ARCH="arm"
			KERNEL_ARCH="arm"
			;;
		odroidn2|odroidc4)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		apple_m1|apple_m2|apple_m3)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		ampere_altra|ampereone)
			ARCH="arm64"
			KERNEL_ARCH="arm64"
			;;
		*)
			die "Unknown target architecture: ${target_arch}"
			;;
	esac
	
	# Set up cross-compilation if needed
	if [[ "${KERNEL_ARCH}" != "$(tc-arch-kernel)" ]]; then
		einfo "Cross-compiling from ${host_arch} to ${KERNEL_ARCH}"
		
		if use llvm; then
			# LLVM/Clang cross-compilation setup
			einfo "Using LLVM/Clang toolchain for cross-compilation"
			
			# Set LLVM=1 to use LLVM tools
			LLVM=1
			
			# Set target triple for Clang
			case "${KERNEL_ARCH}" in
				arm64)
					CLANG_TARGET="aarch64-linux-gnu"
					;;
				arm)
					CLANG_TARGET="arm-linux-gnueabihf"
					;;
				*)
					die "LLVM cross-compilation not supported for ${KERNEL_ARCH}"
					;;
			esac
			
			# Clang-specific flags
			CC="clang --target=${CLANG_TARGET}"
			LD="ld.lld"
			AR="llvm-ar"
			NM="llvm-nm"
			OBJCOPY="llvm-objcopy"
			OBJDUMP="llvm-objdump"
			STRIP="llvm-strip"
			
			# Additional flags for LTO if enabled
			if use lto; then
				einfo "Enabling Link Time Optimization (LTO)"
				# LTO will be configured via kernel config options
			fi
			
		else
			# Traditional GCC cross-compilation
			einfo "Using GCC toolchain for cross-compilation"
			
			case "${KERNEL_ARCH}" in
				arm64)
					if [[ "${host_arch}" == "x86_64" ]]; then
						CROSS_COMPILE="aarch64-linux-gnu-"
						CHOST="aarch64-linux-gnu"
					elif [[ "${host_arch}" == "i686" ]]; then
						CROSS_COMPILE="aarch64-linux-gnu-"
						CHOST="aarch64-linux-gnu"
					else
						CROSS_COMPILE="aarch64-unknown-linux-gnu-"
						CHOST="aarch64-unknown-linux-gnu"
					fi
					;;
				arm)
					if [[ "${host_arch}" == "x86_64" ]]; then
						CROSS_COMPILE="arm-linux-gnueabihf-"
						CHOST="arm-linux-gnueabihf"
					elif [[ "${host_arch}" == "i686" ]]; then
						CROSS_COMPILE="arm-linux-gnueabihf-"
						CHOST="arm-linux-gnueabihf"
					else
						CROSS_COMPILE="arm-unknown-linux-gnueabihf-"
						CHOST="arm-unknown-linux-gnueabihf"
					fi
					;;
				*)
					die "GCC cross-compilation not configured for ${KERNEL_ARCH}"
					;;
			esac
		fi
	else
		einfo "Native compilation detected"
		# Native compilation - use system defaults
		CHOST="$(tc-get-compiler-type)"
		if use llvm; then
			einfo "Using LLVM/Clang for native compilation"
			LLVM=1
			CC="clang"
			LD="ld.lld"
			AR="llvm-ar"
			NM="llvm-nm"
			OBJCOPY="llvm-objcopy"
			OBJDUMP="llvm-objdump"
			STRIP="llvm-strip"
		fi
	fi
	
	# Export all variables
	export ARCH CROSS_COMPILE CHOST LLVM CC LD AR NM OBJCOPY OBJDUMP STRIP
}

pikernel-build_get_targets() {
	targets=()
	configs=()
	for n in bcmrpi bcm2709 bcmrpi3 bcm2711 orangepi5 orangepi5plus rpizero odroidxu4 odroidn2 odroidc4 apple_m1 apple_m2 apple_m3 ampere_altra ampereone
	do
		if use ${n}; then
			ebegin "using $n"
			targets+=( "${n}" )
			mkdir -p "${WORKDIR}/${n}" || die
			configs+=( "${n}/.config" )
		fi
	done
}

# @FUNCTION: pikernel-build_src_configure
# @DESCRIPTION:
# Prepare the toolchain for building the kernel, get the default .config
# or restore savedconfig, and get build tree configured for modprep.
pikernel-build_src_configure() {
	debug-print-function ${FUNCNAME} "${@}"
	pikernel-build_get_targets
	restore_config "${configs[@]}"
	local merge_configs=(
		"${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"/base.config
	)
	use debug || merge_configs+=(
		"${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"/no-debug.config
	)

	for n in "${targets[@]}"
	do
		ebegin "Configuring kernel for ${n}"
		
		# Set up cross-compilation variables for this target
		pikernel-build_get_cross_compile_vars "${n}"
		
		# Generate default config if it doesn't exist
		[[ -f "${WORKDIR}/${n}/.config" ]] || emake O="${WORKDIR}/${n}" "${n}_defconfig"
		
		# Configure the kernel build environment
		internal_src_configure "${n}"
		
		eend $?
	done
	
	pikernel-build_merge_configs "${merge_configs[@]}"
}

# Almost the same as kernel-build_src_configure
# but some parts got chopped off, and
# the last line is changed to support being called in a for-loop.
# TODO: It'd be great if we could call kernel-build_src_configure instead
internal_src_configure() {
	debug-print-function ${FUNCNAME} "${@}"
	local target="${1}"

	# force ld.bfd if we can find it easily (unless using LLVM)
	local LD_TOOL
	if use llvm; then
		LD_TOOL="ld.lld"
	else
		LD_TOOL="$(tc-getLD)"
		if type -P "${LD_TOOL}.bfd" &>/dev/null && [[ -z "${LLVM}" ]]; then
			LD_TOOL+=.bfd
		fi
	fi

	tc-export_build_env
	
	# Build the MAKEARGS array with proper toolchain setup
	MAKEARGS=(
		V=1
		HOSTCC="$(tc-getBUILD_CC)"
		HOSTCXX="$(tc-getBUILD_CXX)"
		HOSTCFLAGS="${BUILD_CFLAGS}"
		HOSTLDFLAGS="${BUILD_LDFLAGS}"
		
		# Architecture and cross-compilation setup
		ARCH="${ARCH}"
	)
	
	# Add toolchain-specific arguments
	if use llvm; then
		MAKEARGS+=(
			LLVM=1
			CC="${CC:-clang}"
			LD="${LD:-ld.lld}"
			AR="${AR:-llvm-ar}"
			NM="${NM:-llvm-nm}"
			OBJCOPY="${OBJCOPY:-llvm-objcopy}"
			OBJDUMP="${OBJDUMP:-llvm-objdump}"
			STRIP="${STRIP:-llvm-strip}"
		)
		
		# Add cross-compilation prefix if needed
		[[ -n "${CROSS_COMPILE}" ]] && MAKEARGS+=( CROSS_COMPILE="${CROSS_COMPILE}" )
		
	else
		# Traditional GCC toolchain
		MAKEARGS+=(
			CROSS_COMPILE="${CROSS_COMPILE:-${CHOST}-}"
			AS="$(tc-getAS)"
			CC="$(tc-getCC)"
			LD="${LD_TOOL}"
			AR="$(tc-getAR)"
			NM="$(tc-getNM)"
			STRIP=":"
			OBJCOPY="$(tc-getOBJCOPY)"
			OBJDUMP="$(tc-getOBJDUMP)"
		)
	fi
	
	emake O="${WORKDIR}/${target}" "${MAKEARGS[@]}" olddefconfig
}

# @FUNCTION: pikernel-build_src_compile
# @DESCRIPTION:
# Compile the kernel sources.
pikernel-build_src_compile() {
	debug-print-function ${FUNCNAME} "${@}"

	pikernel-build_get_targets
	for n in "${targets[@]}"
	do
		ebegin "Compiling kernel for ${n}"
		
		# Set up cross-compilation variables for this target
		pikernel-build_get_cross_compile_vars "${n}"
		
		# Rebuild MAKEARGS for compilation
		internal_src_configure "${n}"
		
		# Compile kernel, modules, and device tree blobs
		emake O="${WORKDIR}/${n}" "${MAKEARGS[@]}" Image modules dtbs
		
		eend $?
	done
}

# @FUNCTION: pikernel-build_src_install
# @DESCRIPTION:
# Install the built kernel along with subset of sources
# into /usr/src/linux-${PV}.  Install the modules.  Save the config.
pikernel-build_src_install() {
	debug-print-function ${FUNCNAME} "${@}"

	pikernel-build_get_targets

	for n in "${targets[@]}"
	do
		ebegin "Installing modules for ${n}"
		
		# Set up cross-compilation variables for this target
		pikernel-build_get_cross_compile_vars "${n}"
		
		# Rebuild MAKEARGS for installation
		internal_src_configure "${n}"
		
		emake O="${WORKDIR}/${n}" "${MAKEARGS[@]}" INSTALL_MOD_PATH="${ED}" INSTALL_PATH="${ED}/boot" modules_install
		
		eend $?
	done

	# note: we're using mv rather than doins to save space and time
	# install main and arch-specific headers first, and scripts
	local kern_arch=$(tc-arch-kernel)
	local ver="${PV}"
	dodir "/usr/src/linux-${ver}/arch/${kern_arch}"
	mv include scripts "${ED}/usr/src/linux-${ver}/" || die
	mv "arch/${kern_arch}/include" "${ED}/usr/src/linux-${ver}/arch/${kern_arch}/" || die
	# some arches need module.lds linker script to build external modules
	if [[ -f arch/${kern_arch}/kernel/module.lds ]]; then
		insinto "/usr/src/linux-${ver}/arch/${kern_arch}/kernel"
		doins "arch/${kern_arch}/kernel/module.lds"
	fi

	# remove everything but Makefile* and Kconfig*
	find -type f '!' '(' -name 'Makefile*' -o -name 'Kconfig*' ')' -delete || die
	find -type l -delete || die
	cp -p -R * "${ED}/usr/src/linux-${ver}/" || die

	cd "${WORKDIR}" || die
	for n in "${targets[@]}"
	do
		ebegin "Installing ${n} kernel and device trees"
		
		# Determine kernel naming based on target
		local KERNEL KERNEL_SUFFIX
		if [[ "${n}" == "bcmrpi3" ]]; then
			KERNEL="kernel8"
			KERNEL_SUFFIX="-v8"
		elif [[ "${n}" == "bcmrpi" ]]; then
			KERNEL="kernel"
			KERNEL_SUFFIX=""
		elif [[ "${n}" == "bcm2709" ]]; then
			KERNEL="kernel7"
			KERNEL_SUFFIX="-v7"
		else
			KERNEL="kernel8-p4"
			KERNEL_SUFFIX="-v8-p4"
		fi
		
		export KERNEL_SUFFIX
		
		# Install device tree blobs
		insinto "/boot/"
		case "${n}" in
			bcmrpi*|bcm27*)
				doins "${n}"/arch/arm*/boot/dts/broadcom/*.dtb 2>/dev/null || true
				;;
			orangepi*)
				doins "${n}"/arch/arm64/boot/dts/rockchip/*.dtb 2>/dev/null || true
				;;
			odroid*)
				doins "${n}"/arch/arm*/boot/dts/amlogic/*.dtb 2>/dev/null || true
				doins "${n}"/arch/arm*/boot/dts/samsung/*.dtb 2>/dev/null || true
				;;
			apple_*)
				doins "${n}"/arch/arm64/boot/dts/apple/*.dtb 2>/dev/null || true
				;;
		esac
		
		# Install kernel image
		local kernel_image
		if [[ -f "${n}/arch/arm64/boot/Image" ]]; then
			kernel_image="${n}/arch/arm64/boot/Image"
		elif [[ -f "${n}/arch/arm/boot/zImage" ]]; then
			kernel_image="${n}/arch/arm/boot/zImage"
		else
			die "No kernel image found for ${n}"
		fi
		
		cp "${kernel_image}" "${n}/${KERNEL}.img" || die
		doins "${n}/${KERNEL}.img"
		
		# Install overlays if they exist
		if [[ -d "${n}/arch/arm64/boot/dts/overlays" ]] || [[ -d "${n}/arch/arm/boot/dts/overlays" ]]; then
			insinto "/boot/overlays"
			doins "${n}"/arch/arm*/boot/dts/overlays/*.dtb* 2>/dev/null || true
		fi

		# Install kernel symbols and module information
		insinto "/usr/src/linux-${ver}${KERNEL_SUFFIX}"
		[[ -f "${n}/System.map" ]] && doins "${n}/System.map"
		[[ -f "${n}/Module.symvers" ]] && doins "${n}/Module.symvers"

		# fix source tree and build dir symlinks
		dosym ../../../usr/src/linux-${ver} /lib/modules/${ver}${KERNEL_SUFFIX}/build
		dosym ../../../usr/src/linux-${ver} /lib/modules/${ver}${KERNEL_SUFFIX}/source
		
		eend $?
	done
	save_config "${configs[@]}"
}

# Hack: Override function from kernel-install eclass to skip checking of kernel.release file(s).
pikernel-build_pkg_preinst() {
	debug-print-function ${FUNCNAME} "${@}"
}

# Hack: Override function from kernel-install eclass to skip building of initramfs.
pikernel-build_pkg_postinst() {
	debug-print-function ${FUNCNAME} "${@}"
	
	# Display information about LLVM usage if enabled
	if use llvm; then
		einfo "Kernel compiled with LLVM/Clang toolchain"
		use lto && einfo "Link Time Optimization (LTO) was enabled"
	fi
}

# @FUNCTION: pikernel-build_merge_configs
# @USAGE: [distro.config...]
# @DESCRIPTION:
# Merge the config files specified as arguments (if any) into
# the '.config' file in the current directory, then merge
# any user-supplied configs from ${BROOT}/etc/kernel/config.d/*.config.
# The '.config' file must exist already and contain the base
# configuration.
pikernel-build_merge_configs() {
	debug-print-function ${FUNCNAME} "${@}"
	pikernel-build_get_targets
	ebegin "Merging kernel configs"
	
	for f in "${targets[@]}"
	do
		# Determine kernel suffix
		local KERNEL_SUFFIX
		if [[ "${f}" == "bcmrpi3" ]]; then
			KERNEL_SUFFIX="-v8"
		elif [[ "${f}" == "bcmrpi" ]]; then
			KERNEL_SUFFIX=""
		elif [[ "${f}" == "bcm2709" ]]; then
			KERNEL_SUFFIX="-v7"
		else
			KERNEL_SUFFIX="-v8-p4"
		fi
		
		export KERNEL_SUFFIX

		[[ -f "${WORKDIR}/${f}/.config" ]] || die "${FUNCNAME}: ${f}/.config does not exist"
		has .config "${@}" && die "${FUNCNAME}: do not specify .config as parameter"

		local shopt_save=$(shopt -p nullglob)
		shopt -s nullglob
		local user_configs=( "${BROOT}"/etc/kernel/config.d/*.config )
		${shopt_save}

		if [[ ${#user_configs[@]} -gt 0 ]]; then
			elog "User config files are being applied to ${f}:"
			local x
			for x in "${user_configs[@]}"; do
				elog "- ${x}"
			done
		fi

		cd "${WORKDIR}/${f}" || die

		./scripts/kconfig/merge_config.sh -m -r ".config" "${@}" "${user_configs[@]}" || die
		
		# Set LOCALVERSION based on target
		sed -i -E "s_CONFIG_LOCALVERSION=.*\$_CONFIG_LOCALVERSION=\"${KERNEL_SUFFIX}\"_" .config || die
		
		# Enable LLVM-specific options if using LLVM
		if use llvm; then
			# Enable Clang support
			sed -i -E 's/^# CONFIG_CC_IS_CLANG is not set$/CONFIG_CC_IS_CLANG=y/' .config || true
			echo "CONFIG_CC_IS_CLANG=y" >> .config
			
			if use lto; then
				# Enable LTO if supported by the kernel version
				echo "CONFIG_LTO_CLANG=y" >> .config
				echo "CONFIG_LTO_CLANG_THIN=y" >> .config
				echo "# CONFIG_LTO_CLANG_FULL is not set" >> .config
			fi
		fi

		cd - >/dev/null || die
	done
	eend $?
}

EXPORT_FUNCTIONS src_configure src_compile src_install pkg_postinst
