# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC

PKG_NAME="atf"
PKG_VERSION="v2.1"
PKG_SHA256="7c4c00a4f28d3cfbb235fd1a1fb28c4d2fc1d657c9301686e7d8824ef575d059"
PKG_ARCH="arm aarch64"
PKG_LICENSE="BSD-3c"
PKG_SITE="https://github.com/ARM-software/arm-trusted-firmware"
PKG_URL="https://github.com/ARM-software/arm-trusted-firmware/archive/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="ARM Trusted Firmware is a reference implementation of secure world software, including a Secure Monitor executing at Exception Level 3 and various Arm interface standards."
PKG_TOOLCHAIN="manual"

[ -n "$KERNEL_TOOLCHAIN" ] && PKG_DEPENDS_TARGET+=" gcc-arm-$KERNEL_TOOLCHAIN:host"

make_target() {
  CROSS_COMPILE="$TARGET_KERNEL_PREFIX" LDFLAGS="" CFLAGS="" make PLAT=$ATF_PLATFORM bl31
}

post_make_target() {
  cp -av build/$ATF_PLATFORM/release/bl31.bin .
}
