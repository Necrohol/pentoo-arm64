# @ECLASS: milkvkernel.eclass
# @MAINTAINER:
# https://github.com/Necrohol/
# @SUPPORTED_EAPIS: 7
# @BLURB: Build mechanics for Distribution Kernels for various devices
# @DESCRIPTION:
# This eclass provides the logic to build a Distribution Kernel for
# various devices from source and install it. Post-install and test
# logic is inherited from kernel-install.eclass.

inherit kernel-build

IUSE="riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive"
REQUIRED_USE="|| ( riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive )"

SLOT="0"

milkvkernel_get_targets() {
    targets=()
    configs=()
    for n in riscv64 milkv_mars milkv_pioneer milkv_jupiter sifive
    do
        if use ${n}; then
            ebegin "using $n"
            targets+=( "${n}" )
            mkdir -p "${WORKDIR}/${n}" || die
            configs+=( "${n}/.config" )
        fi
    done
}

milkvkernel_src_configure() {
    debug-print-function ${FUNCNAME} "${@}"
    milkvkernel_get_targets

    for n in "${targets[@]}"
    do
        if [[ $(uname -m) == "riscv64" ]]; then
            CHOST=riscv64-unknown-linux-gnu
            # No need to cross-compile, proceed as normal
            [[ -f $n/.config ]] || emake O="${WORKDIR}/${n}" "${n}_defconfig"
        else
            case $(uname -m) in
                "x86_64")
                    ARCH=amd64
                    CROSS_COMPILE=riscv64-unknown-linux-gnu-
                    CHOST=riscv64-unknown-linux-gnu
                    ;;
                *)
                    echo "Unsupported architecture: $(uname -m)"
                    exit 1
                    ;;
            esac
            export CHOST
            [[ -f $n/.config ]] || emake O="${WORKDIR}/${n}" ARCH=${ARCH} CROSS_COMPILE=${CROSS_COMPILE} "${n}_defconfig"
        fi

        internal_src_configure $n
        ebegin "Selecting Kernel Config"
    done
}

EXPORT_FUNCTIONS src_configure src_compile src_install pkg_postinst
