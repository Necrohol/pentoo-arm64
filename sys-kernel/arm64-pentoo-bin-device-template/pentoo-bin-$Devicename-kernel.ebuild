# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit pikernel-build

DESCRIPTION="Binary package for Pentoo kernel for $Devicename"
HOMEPAGE="https://www.pentoo.ch"

LICENSE="metapackage"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="${SET_USE}"

DEPEND="
	sys-apps/dtc[python,yaml]
	app-misc/jq
"
RDEPEND="
	>=sys-kernel/pentoo-sources-${minimum-pv}
	<=sys-kernel/pentoo-sources-${maximum-pv}
"

URI_pentoo_base_config="https://raw.githubusercontent.com/pentoo/pentoo-overlay/master/sys-kernel/pentoo-sources/files/config-amd64-${PV}"
URI_rpi4="https://github.com/raspberrypi/linux/tree/rpi-6.1.y/arch/arm64/configs"
URI_rpi5="https://github.com/raspberrypi/linux/tree/rpi-6.1.y/arch/arm64/configs"
URI_orangepi5="https://github.com/orangepi-xunlong/orangepi-build/tree/main/external/config/orangepi5"
URI_orangepi5_plus="https://github.com/orangepi-xunlong/orangepi-build/tree/main/external/config/orangepi5_plus"
URI_apple_m1="https://github.com/AsahiLinux/linux/tree/asahi/arch/arm64/configs"
URI_apple_m2="https://github.com/AsahiLinux/linux/tree/asahi/arch/arm64/configs"
URI_apple_m3="https://github.com/AsahiLinux/linux/tree/asahi/arch/arm64/configs"
URI_apple_m4="https://github.com/AsahiLinux/linux/tree/asahi/arch/arm64/configs"
URI_pine64="https://github.com/pine64/linux/tree/pine64-kernel/arch/arm64/configs"
URI_khadas_ampere_altra="https://github.com/khadas/linux/tree/khadas-vims-5.15/arch/arm64/configs"

pkg_setup() {
	if use rpi4; then
		set-device="bcm2711"
	elif use rpi5; then
		set-device="bcm2711"
	elif use orangepi5; then
		set-device="rockchip"
	elif use orangepi5_plus; then
		set-device="rockchip"
	elif use apple_m1; then
		set-device="apple-m1"
	elif use apple_m2; then
		set-device="apple-m2"
	elif use apple_m3; then
		set-device="apple-m3"
	elif use apple_m4; then
		set-device="apple-m4"
	elif use pine64; then
		set-device="allwinner"
	elif use khadas_ampere_altra; then
		set-device="ampere"
	fi

	ARCH="arm64"

	if use build; then
		if use lts; then
			KERNEL_SOURCES="/usr/src/pentoo-${minimum-pv}"
		else
			KERNEL_SOURCES="/usr/src/pentoo-${maximum-pv}"
		fi
	else
		KERNEL_SOURCES="/usr/src/linux"
	fi

	pikernel-build_pkg_setup
}

src_prepare() {
	default

	# Fetch the base Pentoo amd64 config
	wget -O "${WORKDIR}/pentoo-base.config" "${URI_pentoo_base_config}"

	if [[ "${set-device}" == "all" ]]; then
		# Combine all device configs for arm64
		local config_files=(
			"${FILESDIR}/config-rpi5-${PV}"
			"${FILESDIR}/config-orangepi5-${PV}"
			"${FILESDIR}/config-orangepi5-plus-${PV}"
			"${FILESDIR}/config-apple-m1-${PV}"
			"${FILESDIR}/config-apple-m2-${PV}"
			"${FILESDIR}/config-apple-m3-${PV}"
			"${FILESDIR}/config-apple-m4-${PV}"
			"${FILESDIR}/config-pine64-${PV}"
			"${FILESDIR}/config-khadas-ampere-altra-${PV}"
			# Add more config files as needed
		)

		cat "${WORKDIR}/pentoo-base.config" "${config_files[@]}" > "${WORKDIR}/pentoo-${Devicename}.config"
	else
		cat "${WORKDIR}/pentoo-base.config" "${FILESDIR}/config-${set-device}-${PV}" > "${WORKDIR}/pentoo-${Devicename}.config"
	fi

	# Insert CONFIG_LOCALVERSION into the config
	echo "CONFIG_LOCALVERSION=\"pentoo-${PV}-arm64-${Devicename}\"" >> "${WORKDIR}/pentoo-${Devicename}.config"

	cp "${WORKDIR}/pentoo-${Devicename}.config" "${KERNEL_SOURCES}/.config"
	cp "${WORKDIR}/pentoo-${Devicename}.config" "/etc/portage/kernels/sys-kernel-pentoo-${PV}-arm64-${Devicename}.config"

	# Force combined configs to arm64 and fix any discrepancies
	make ARCH=arm64 silentoldconfig
}

src_configure() {
	pikernel-build_src_configure
}

src_compile() {
	# Enable newer kernel modules to auto build by default
	# Build arm64 device trees by default
	pikernel-build_src_compile
}

src_install() {
	pikernel-build_src_install
}