# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
inherit riscvkernel

DESCRIPTION="Binary package for Pentoo kernel for RISC-V $Devicename"
HOMEPAGE="https://www.pentoo.ch"
LICENSE="metapackage"
SLOT="0"
KEYWORDS="~riscv"
IUSE="${SET_USE}"

DEPEND="
	sys-apps/dtc[python,yaml]
	app-misc/jq
	sys-devel/crossdev
"

RDEPEND="
	>=sys-kernel/pentoo-sources-${minimum-pv}
	<=sys-kernel/pentoo-sources-${maximum-pv}
"

# RISC-V device configuration URIs
URI_pentoo_base_config="https://raw.githubusercontent.com/pentoo/pentoo-overlay/master/sys-kernel/pentoo-sources/files/config-riscv64-${PV}"
URI_sifive_unmatched="https://github.com/sifive/meta-sifive/tree/master/recipes-kernel/linux/files"
URI_sifive_unleashed="https://github.com/sifive/meta-sifive/tree/master/recipes-kernel/linux/files"
URI_starfive_visionfive2="https://github.com/starfive-tech/linux/tree/JH7110_VisionFive2_devel/arch/riscv/configs"
URI_starfive_visionfive="https://github.com/starfive-tech/linux/tree/visionfive-5.15.y/arch/riscv/configs"
URI_canaan_k210="https://github.com/kendryte/linux/tree/k210-5.6/arch/riscv/configs"
URI_thead_c906="https://github.com/T-head-Semi/linux/tree/linux-5.10.y/arch/riscv/configs"
URI_milk_v_pioneer="https://github.com/milkv-community/linux-riscv/tree/riscv/arch/riscv/configs"
URI_lichee_rv="https://github.com/sipeed/LicheeRV-Nano-Build/tree/main/linux/arch/riscv/configs"
URI_nezha_d1="https://github.com/smaeul/linux/tree/riscv/d1-wip/arch/riscv/configs"
URI_beaglev_ahead="https://github.com/beagleboard/linux/tree/beaglev-ahead/arch/riscv/configs"
URI_banana_pi_f3="https://github.com/BPI-SINOVOIP/BPI-F3-BSP/tree/main/linux-6.1/arch/riscv/configs"

pkg_setup() {
	# Set device-specific configurations
	if use sifive_unmatched; then
		set_device="sifive-unmatched"
	elif use sifive_unleashed; then
		set_device="sifive-unleashed"
	elif use starfive_visionfive2; then
		set_device="starfive-visionfive2"
	elif use starfive_visionfive; then
		set_device="starfive-visionfive"
	elif use canaan_k210; then
		set_device="canaan-k210"
	elif use thead_c906; then
		set_device="thead-c906"
	elif use milk_v_pioneer; then
		set_device="milk-v-pioneer"
	elif use lichee_rv; then
		set_device="lichee-rv"
	elif use nezha_d1; then
		set_device="nezha-d1"
	elif use beaglev_ahead; then
		set_device="beaglev-ahead"
	elif use banana_pi_f3; then
		set_device="banana-pi-f3"
	fi
	
	ARCH="riscv64"
	CROSS_COMPILE="riscv64-unknown-linux-gnu-"
	
	if use build; then
		if use lts; then
			KERNEL_SOURCES="/usr/src/pentoo-${minimum-pv}"
		else
			KERNEL_SOURCES="/usr/src/pentoo-${maximum-pv}"
		fi
	else
		KERNEL_SOURCES="/usr/src/linux"
	fi
	
	riscvkernel_pkg_setup
}

src_prepare() {
	default
	
	# Fetch the base Pentoo RISC-V config
	if [[ -n "${URI_pentoo_base_config}" ]]; then
		wget -O "${WORKDIR}/pentoo-base.config" "${URI_pentoo_base_config}" || \
		# Fallback to generic RISC-V defconfig if Pentoo-specific doesn't exist
		cp "${KERNEL_SOURCES}/arch/riscv/configs/defconfig" "${WORKDIR}/pentoo-base.config"
	else
		cp "${KERNEL_SOURCES}/arch/riscv/configs/defconfig" "${WORKDIR}/pentoo-base.config"
	fi
	
	if [[ "${set_device}" == "all" ]]; then
		# Combine all RISC-V device configs
		local config_files=(
			"${FILESDIR}/config-sifive-unmatched-${PV}"
			"${FILESDIR}/config-sifive-unleashed-${PV}"
			"${FILESDIR}/config-starfive-visionfive2-${PV}"
			"${FILESDIR}/config-starfive-visionfive-${PV}"
			"${FILESDIR}/config-canaan-k210-${PV}"
			"${FILESDIR}/config-thead-c906-${PV}"
			"${FILESDIR}/config-milk-v-pioneer-${PV}"
			"${FILESDIR}/config-lichee-rv-${PV}"
			"${FILESDIR}/config-nezha-d1-${PV}"
			"${FILESDIR}/config-beaglev-ahead-${PV}"
			"${FILESDIR}/config-banana-pi-f3-${PV}"
		)
		cat "${WORKDIR}/pentoo-base.config" "${config_files[@]}" > "${WORKDIR}/pentoo-${Devicename}.config"
	else
		cat "${WORKDIR}/pentoo-base.config" "${FILESDIR}/config-${set_device}-${PV}" > "${WORKDIR}/pentoo-${Devicename}.config"
	fi
	
	# Add RISC-V specific kernel configurations
	cat >> "${WORKDIR}/pentoo-${Devicename}.config" << EOF
# RISC-V specific configurations
CONFIG_RISCV=y
CONFIG_64BIT=y
CONFIG_RISCV_SBI=y
CONFIG_RISCV_SBI_V01=y
CONFIG_RISCV_M_MODE=n
CONFIG_RISCV_ISA_RV64I=y
CONFIG_RISCV_ISA_C=y
CONFIG_RISCV_ISA_A=y
CONFIG_RISCV_ISA_M=y
CONFIG_RISCV_ISA_F=y
CONFIG_RISCV_ISA_D=y
CONFIG_RISCV_ISA_V=y
CONFIG_FPU=y
CONFIG_SMP=y
CONFIG_HOTPLUG_CPU=y
CONFIG_SOC_SIFIVE=y
CONFIG_SOC_STARFIVE=y
CONFIG_SOC_THEAD=y
CONFIG_SOC_CANAAN=y
CONFIG_SOC_SPACEMIT=y
EOF
	
	# Insert CONFIG_LOCALVERSION into the config
	echo "CONFIG_LOCALVERSION=\"-pentoo-${PV}-riscv64-${Devicename}\"" >> "${WORKDIR}/pentoo-${Devicename}.config"
	
	# Copy config files
	cp "${WORKDIR}/pentoo-${Devicename}.config" "${KERNEL_SOURCES}/.config"
	cp "${WORKDIR}/pentoo-${Devicename}.config" "/etc/portage/kernels/sys-kernel-pentoo-${PV}-riscv64-${Devicename}.config"
	
	# Configure for RISC-V architecture and resolve config conflicts
	cd "${KERNEL_SOURCES}" || die
	make ARCH=riscv64 CROSS_COMPILE="${CROSS_COMPILE}" olddefconfig
}

src_configure() {
	# Set RISC-V specific environment variables
	export ARCH=riscv64
	export CROSS_COMPILE="${CROSS_COMPILE}"
	
	riscvkernel_src_configure
}

src_compile() {
	# Enable RISC-V specific compilation flags
	export ARCH=riscv64
	export CROSS_COMPILE="${CROSS_COMPILE}"
	
	# Build RISC-V device trees by default
	emake ARCH=riscv64 CROSS_COMPILE="${CROSS_COMPILE}" dtbs
	
	riscvkernel_src_compile
}

src_install() {
	# Install RISC-V device tree blobs
	if [[ -d "${KERNEL_SOURCES}/arch/riscv64/boot/dts" ]]; then
		insinto /boot/dtbs
		doins "${KERNEL_SOURCES}"/arch/riscv64/boot/dts/*/*.dtb
	fi
	
	riscvkernel_src_install
}
