# @ECLASS: riscvkernel.eclass
# @MAINTAINER:
# https://github.com/Necrohol/
# @SUPPORTED_EAPIS: 7
# @BLURB: Build mechanics for Distribution Kernels for various devices
# @DESCRIPTION:
# This eclass provides the logic to build a Distribution Kernel for
# various devices from source and install it. Post-install and test
# logic is inherited from kernel-install.eclass.

inherit kernel-build

IUSE="riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive bpi_f3 +gcc llvm"
REQUIRED_USE="|| ( riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive bpi_f3 )
             ^^ ( gcc llvm )"
SLOT="0"

riscvkernel_get_targets() {
    targets=()
    configs=()
    for n in riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive bpi_f3
    do
        if use ${n}; then
            ebegin "using $n"
            targets+=( "${n}" )
            mkdir -p "${WORKDIR}/${n}" || die
            configs+=( "${n}/.config" )
        fi
    done
}

riscvkernel_setup_cross_compile() {
    local host_arch=$(uname -m)
    
    if [[ "${host_arch}" == "riscv64" ]]; then
        # Native compilation on RISC-V
        CHOST="riscv64-unknown-linux-gnu"
        unset ARCH CROSS_COMPILE
        einfo "Native RISC-V compilation detected"
        
        # Set compiler for native compilation
        if use llvm; then
            export CC="clang"
            export CXX="clang++"
            export LD="ld.lld"
            export AR="llvm-ar"
            export NM="llvm-nm"
            export STRIP="llvm-strip"
            export OBJCOPY="llvm-objcopy"
            export OBJDUMP="llvm-objdump"
            export READELF="llvm-readelf"
            einfo "Using LLVM/Clang for native compilation"
        else
            unset CC CXX LD AR NM STRIP OBJCOPY OBJDUMP READELF
            einfo "Using GCC for native compilation"
        fi
    else
        # Cross-compilation setup
        case "${host_arch}" in
            "x86_64"|"amd64")
                ARCH="riscv"
                CHOST="riscv64-unknown-linux-gnu"
                ;;
            "aarch64"|"arm64")
                ARCH="riscv"
                CHOST="riscv64-unknown-linux-gnu"
                ;;
            "armv7l"|"armhf")
                ARCH="riscv"
                CHOST="riscv64-unknown-linux-gnu"
                ;;
            *)
                eerror "Unsupported host architecture for cross-compilation: ${host_arch}"
                die "Cannot cross-compile from ${host_arch} to RISC-V"
                ;;
        esac
        
        if use llvm; then
            # LLVM/Clang cross-compilation
            export CC="clang"
            export CXX="clang++"
            export LD="ld.lld"
            export AR="llvm-ar"
            export NM="llvm-nm"
            export STRIP="llvm-strip"
            export OBJCOPY="llvm-objcopy"
            export OBJDUMP="llvm-objdump"
            export READELF="llvm-readelf"
            export LLVM="1"
            export LLVM_IAS="1"
            # Clang target triple
            export CROSS_COMPILE="riscv64-linux-gnu-"
            # Additional Clang flags for RISC-V
            export CLANG_TRIPLE="riscv64-linux-gnu"
            
            einfo "Cross-compilation setup: ${host_arch} -> RISC-V (LLVM/Clang)"
            einfo "ARCH=${ARCH}, CC=${CC}, LLVM=${LLVM}"
            
            # Verify LLVM tools are available
            local missing_tools=()
            for tool in clang clang++ ld.lld llvm-ar llvm-nm llvm-strip llvm-objcopy llvm-objdump llvm-readelf; do
                if ! command -v "${tool}" >/dev/null 2>&1; then
                    missing_tools+=("${tool}")
                fi
            done
            
            if [[ ${#missing_tools[@]} -gt 0 ]]; then
                eerror "Missing LLVM tools: ${missing_tools[*]}"
                eerror "Please install sys-devel/llvm with RISC-V support"
                die "LLVM cross-compilation tools not available"
            fi
            
            # Check if Clang supports RISC-V target
            if ! clang --print-targets 2>/dev/null | grep -q riscv; then
                eerror "Clang does not support RISC-V target"
                eerror "Please install LLVM with RISC-V backend support"
                die "RISC-V target not supported by Clang"
            fi
        else
            # GCC cross-compilation
            CROSS_COMPILE="riscv64-unknown-linux-gnu-"
            unset CC CXX LD AR NM STRIP OBJCOPY OBJDUMP READELF LLVM LLVM_IAS CLANG_TRIPLE
            
            einfo "Cross-compilation setup: ${host_arch} -> RISC-V (GCC)"
            einfo "ARCH=${ARCH}, CROSS_COMPILE=${CROSS_COMPILE}"
            
            # Verify GCC cross-compiler is available
            if ! command -v "${CROSS_COMPILE}gcc" >/dev/null 2>&1; then
                eerror "Cross-compiler ${CROSS_COMPILE}gcc not found"
                eerror "Please install sys-devel/crossdev and run:"
                eerror "  crossdev -t riscv64-unknown-linux-gnu"
                die "GCC cross-compiler not available"
            fi
        fi
        
        export ARCH CROSS_COMPILE CHOST
    fi
}

riscvkernel_src_configure() {
    debug-print-function ${FUNCNAME} "${@}"
    riscvkernel_get_targets
    riscvkernel_setup_cross_compile
    
    for n in "${targets[@]}"
    do
        ebegin "Configuring kernel for ${n}"
        
        # Generate .config if it doesn't exist
        if [[ ! -f "${WORKDIR}/${n}/.config" ]]; then
            local make_args=("O=${WORKDIR}/${n}")
            
            if [[ -n "${ARCH}" ]]; then
                make_args+=("ARCH=${ARCH}")
            fi
            
            if use llvm; then
                make_args+=("LLVM=1" "LLVM_IAS=1")
                if [[ -n "${CLANG_TRIPLE}" ]]; then
                    make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
                fi
            elif [[ -n "${CROSS_COMPILE}" ]]; then
                make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
            fi
            
            emake "${make_args[@]}" "${n}_defconfig" || die "Failed to create ${n} defconfig"
        fi
        
        # Call internal configuration function if it exists
        if declare -f internal_src_configure >/dev/null 2>&1; then
            internal_src_configure "${n}"
        fi
        
        eend $? "Kernel configuration for ${n}"
    done
}

riscvkernel_src_compile() {
    debug-print-function ${FUNCNAME} "${@}"
    riscvkernel_get_targets
    riscvkernel_setup_cross_compile
    
    for n in "${targets[@]}"
    do
        ebegin "Compiling kernel for ${n}"
        
        local make_args=("O=${WORKDIR}/${n}" "-j$(nproc)")
        
        if [[ -n "${ARCH}" ]]; then
            make_args+=("ARCH=${ARCH}")
        fi
        
        if use llvm; then
            make_args+=("LLVM=1" "LLVM_IAS=1")
            if [[ -n "${CLANG_TRIPLE}" ]]; then
                make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
            fi
        elif [[ -n "${CROSS_COMPILE}" ]]; then
            make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
        fi
        
        emake "${make_args[@]}" || die "Failed to compile ${n} kernel"
        eend $? "Kernel compilation for ${n}"
    done
}

riscvkernel_src_install() {
    debug-print-function ${FUNCNAME} "${@}"
    riscvkernel_get_targets
    riscvkernel_setup_cross_compile
    
    for n in "${targets[@]}"
    do
        ebegin "Installing kernel for ${n}"
        
        # Create target-specific installation directory
        local install_dir="/boot/${n}"
        dodir "${install_dir}"
        
        local make_args=("O=${WORKDIR}/${n}" "INSTALL_PATH=${ED}${install_dir}")
        
        if [[ -n "${ARCH}" ]]; then
            make_args+=("ARCH=${ARCH}")
        fi
        
        if use llvm; then
            make_args+=("LLVM=1" "LLVM_IAS=1")
            if [[ -n "${CLANG_TRIPLE}" ]]; then
                make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
            fi
        elif [[ -n "${CROSS_COMPILE}" ]]; then
            make_args+=("CROSS_COMPILE=${CROSS_COMPILE}")
        fi
        
        emake "${make_args[@]}" install || die "Failed to install ${n} kernel"
        
        # Install device tree blobs if they exist
        if [[ -d "${WORKDIR}/${n}/arch/riscv/boot/dts" ]]; then
            find "${WORKDIR}/${n}/arch/riscv/boot/dts" -name "*.dtb" -exec \
                cp {} "${ED}${install_dir}/" \; 2>/dev/null || true
        fi
        
        eend $? "Kernel installation for ${n}"
    done
}

riscvkernel_pkg_postinst() {
    debug-print-function ${FUNCNAME} "${@}"
    
    einfo "Kernel installation completed for the following targets:"
    for n in "${targets[@]}"
    do
        einfo "  - ${n}: /boot/${n}/"
    done
    
    if use llvm; then
        einfo "Compiled with LLVM/Clang toolchain"
    else
        einfo "Compiled with GCC toolchain"
    fi
    
    einfo ""
    einfo "Please update your bootloader configuration to use the new kernel(s)."
    einfo "Device tree blobs (if any) are installed alongside the kernel images."
}

EXPORT_FUNCTIONS src_configure src_compile src_install pkg_postinst
