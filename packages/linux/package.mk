# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2017-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="linux"
PKG_LICENSE="GPL"
PKG_SITE="http://www.kernel.org"
PKG_DEPENDS_HOST="ccache:host openssl:host"
PKG_DEPENDS_TARGET="toolchain linux:host kmod:host xz:host wireless-regdb keyutils initramfs:init $KERNEL_EXTRA_DEPENDS_TARGET"
PKG_NEED_UNPACK="$LINUX_DEPENDS $(get_pkg_directory initramfs) $(get_pkg_variable initramfs PKG_NEED_UNPACK)"
PKG_LONGDESC="This package contains a precompiled kernel image and the modules."
PKG_IS_KERNEL_PKG="yes"
PKG_STAMP="$KERNEL_TARGET $KERNEL_MAKE_EXTRACMD"

PKG_PATCH_DIRS="$LINUX"

case "$LINUX" in
  rockchip-4.4)
    PKG_VERSION="8394b6656aeea884ae576a85c11d6280595445fd"
    PKG_URL="https://github.com/mrfixit2001/rockchip-kernel/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    ;;
  odroidgoA-4.4)
    PKG_VERSION="fbfe5c30bf5643f44cc8c87c9b53b1ba2a0bfa49"
    PKG_SHA256="ca4071dcd23a6c5b8051b814ec6bcf2a73e0569422156be143ac3f50df3f7d6b"
    PKG_URL="https://github.com/hardkernel/linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    ;;
  raspberrypi)
    # NOTE: if updating also update bcm2835-bootloader to corresponding firmware
    PKG_VERSION="58f672b8da4a4094283a7fcb29dc63f3eb7ddb62"
    # PKG_SHA256="d229567885723440e38a0815afda58e835142dbd0d3609399f3e8d5b81080bfc"
    PKG_URL="https://github.com/raspberrypi/linux/archive/$PKG_VERSION.tar.gz"
    PKG_SOURCE_NAME="linux-$LINUX-$PKG_VERSION.tar.gz"
    PKG_PATCH_DIRS="rpi joycon dualsense"
    ;;
  odroidxu4-4.14)
    PKG_VERSION="864c4519b77763274b61a035b33bc92f71084b59"
    PKG_SHA256="4cbafde263437b5c9ab5c4a2496866eb19922fb4c80cf5c6ef3c8b65cf1936be"
    PKG_URL="https://github.com/hardkernel/linux/archive/$PKG_VERSION.tar.gz"
    ;;
  mainline-5.10)
    PKG_VERSION="5.10.47"
   # PKG_SHA256=" "
    PKG_URL="https://www.kernel.org/pub/linux/kernel/v5.x/$PKG_NAME-$PKG_VERSION.tar.xz"
    PKG_PATCH_DIRS="default joycon dualsense"
    ;;
  switch)
    PKG_VERSION="switch"
    PKG_URL="https://gitlab.com/Azkali/l4t-kernel-4.9/-/archive/lakka-3.3.0/l4t-kernel-4.9-lakka-3.3.0.tar.gz"
    PKG_PATCH_DIRS=""
    ;;
  *)
    PKG_VERSION="5.1.18"
    PKG_SHA256="6013e7dcf59d7c1b168d8edce3dbd61ce340ff289541f920dbd0958bef98f36a"
    PKG_URL="https://www.kernel.org/pub/linux/kernel/v5.x/$PKG_NAME-$PKG_VERSION.tar.xz"
    PKG_PATCH_DIRS="default"
    ;;
esac

PKG_KERNEL_CFG_FILE=$(kernel_config_path) || die

if [ -n "$KERNEL_TOOLCHAIN" ]; then
  PKG_DEPENDS_HOST="$PKG_DEPENDS_HOST gcc-arm-$KERNEL_TOOLCHAIN:host"
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET gcc-arm-$KERNEL_TOOLCHAIN:host"
  HEADERS_ARCH=$TARGET_ARCH
fi

if [ "$PKG_BUILD_PERF" != "no" ] && grep -q ^CONFIG_PERF_EVENTS= $PKG_KERNEL_CFG_FILE ; then
  PKG_BUILD_PERF="yes"
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET binutils elfutils libunwind zlib openssl"
fi

if [ "$TARGET_ARCH" = "x86_64" -o "$TARGET_ARCH" = "i386" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET intel-ucode:host kernel-firmware elfutils:host pciutils"
elif [ "$TARGET_ARCH" = "arm" -a "$DEVICE" = "iMX6" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET kernel-firmware"
elif [ "$TARGET_ARCH" = "aarch64" ] && [ "$DEVICE" = "Switch" ]; then
  PKG_DEPENDS_HOST="$PKG_DEPENDS_HOST gcc-linaro-aarch64-linux-gnu:host"
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET gcc-linaro-aarch64-linux-gnu:host"
  export PATH=$TOOLCHAIN/lib/gcc-linaro-aarch64-linux-gnu/bin/:$PATH
  TARGET_PREFIX=aarch64-linux-gnu-
  OLD_CROSS_COMPILE=$CROSS_COMPILE
  export CROSS_COMPILE=$TARGET_PREFIX # necessary for Linux 5
  PKG_MAKE_OPTS_HOST="ARCH=$TARGET_ARCH headers_check"
fi

if [[ "$KERNEL_TARGET" = uImage* ]]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET u-boot-tools:host"
fi

post_patch() {
  cp $PKG_KERNEL_CFG_FILE $PKG_BUILD/.config

  sed -i -e "s|^CONFIG_INITRAMFS_SOURCE=.*$|CONFIG_INITRAMFS_SOURCE=\"$(kernel_initramfs_confs) $BUILD/initramfs\"|" $PKG_BUILD/.config
  sed -i -e "/CONFIG_INITRAMFS_ROOT_UID/d" -e "/CONFIG_INITRAMFS_ROOT_GID/d" -e "/CONFIG_INITRAMFS_SOURCE=.../a CONFIG_INITRAMFS_ROOT_UID=0\nCONFIG_INITRAMFS_ROOT_GID=0" $PKG_BUILD/.config

  # set default hostname based on $DISTRONAME
  sed -i -e "s|@DISTRONAME@|$DISTRONAME|g" $PKG_BUILD/.config

  # disable swap support if not enabled
  if [ ! "$SWAP_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_SWAP=.*$|# CONFIG_SWAP is not set|" $PKG_BUILD/.config
  fi

  # disable nfs support if not enabled
  if [ ! "$NFS_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_NFS_FS=.*$|# CONFIG_NFS_FS is not set|" $PKG_BUILD/.config
  fi

  # disable cifs support if not enabled
  if [ ! "$SAMBA_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_CIFS=.*$|# CONFIG_CIFS is not set|" $PKG_BUILD/.config
  fi

  # disable iscsi support if not enabled
  if [ ! "$ISCSI_SUPPORT" = yes ]; then
    sed -i -e "s|^CONFIG_SCSI_ISCSI_ATTRS=.*$|# CONFIG_SCSI_ISCSI_ATTRS is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_TCP=.*$|# CONFIG_ISCSI_TCP is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_BOOT_SYSFS=.*$|# CONFIG_ISCSI_BOOT_SYSFS is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_IBFT_FIND=.*$|# CONFIG_ISCSI_IBFT_FIND is not set|" $PKG_BUILD/.config
    sed -i -e "s|^CONFIG_ISCSI_IBFT=.*$|# CONFIG_ISCSI_IBFT is not set|" $PKG_BUILD/.config
  fi

  # install extra dts files
  for f in $PROJECT_DIR/$PROJECT/config/*-overlay.dts; do
    [ -f "$f" ] && cp -v $f $PKG_BUILD/arch/$TARGET_KERNEL_ARCH/boot/dts/overlays || true
  done
  if [ -n "$DEVICE" ]; then
    for f in $PROJECT_DIR/$PROJECT/devices/$DEVICE/config/*-overlay.dts; do
      [ -f "$f" ] && cp -v $f $PKG_BUILD/arch/$TARGET_KERNEL_ARCH/boot/dts/overlays || true
    done
  fi

  #host gcc 10 build issue
  sed -i '/YYLTYPE yylloc/d' $PKG_BUILD/scripts/dtc/dtc-lexer.l

}

make_host() {
  if [ "$DEVICE" = "Switch" ]; then
    make \
      ARCH=arm64 \
      CROSS_COMPILE=$TARGET_PREFIX \
      olddefconfig
     make \
       ARCH=arm64 \
       CROSS_COMPILE=$TARGET_PREFIX \
       prepare
     make \
       ARCH=arm64 \
       CROSS_COMPILE=$TARGET_PREFIX \
       modules_prepare
     make \
       ARCH=arm64 \
       headers_check
  else
    make \
      ARCH=${HEADERS_ARCH:-$TARGET_KERNEL_ARCH} \
      HOSTCC="$TOOLCHAIN/bin/host-gcc" \
      HOSTCXX="$TOOLCHAIN/bin/host-g++" \
      HOSTCFLAGS="$HOST_CFLAGS" \
      HOSTCXXFLAGS="$HOST_CXXFLAGS" \
      HOSTLDFLAGS="$HOST_LDFLAGS" \
      headers_check
  fi
}

makeinstall_host() {
  if [ "$DEVICE" = "Switch" ]; then
    make \
      ARCH=arm64 \
      CROSS_COMPILE=$TARGET_PREFIX \
      INSTALL_HDR_PATH=dest \
      headers_install
  else
    make \
      ARCH=${HEADERS_ARCH:-$TARGET_KERNEL_ARCH} \
      HOSTCC="$TOOLCHAIN/bin/host-gcc" \
      HOSTCXX="$TOOLCHAIN/bin/host-g++" \
      HOSTCFLAGS="$HOST_CFLAGS" \
      HOSTCXXFLAGS="$HOST_CXXFLAGS" \
      HOSTLDFLAGS="$HOST_LDFLAGS" \
      INSTALL_HDR_PATH=dest \
      headers_install
  fi

  mkdir -p $SYSROOT_PREFIX/usr/include
  cp -R dest/include/* $SYSROOT_PREFIX/usr/include
}

pre_make_target() {
  ( cd $ROOT
    rm -rf $BUILD/initramfs
    rm -f ${STAMPS_INSTALL}/initramfs/install_target ${STAMPS_INSTALL}/*/install_init
    $SCRIPTS/install initramfs
  )
  pkg_lock_status "ACTIVE" "linux:target" "build"

  if [ "$TARGET_ARCH" = "x86_64" -o "$TARGET_ARCH" = "i386" ]; then
    # copy some extra firmware to linux tree
    mkdir -p $PKG_BUILD/external-firmware
      cp -a $(get_build_dir kernel-firmware)/.copied-firmware/{amdgpu,amd-ucode,i915,nvidia,radeon,e100,rtl_nic} $PKG_BUILD/external-firmware
      cp -a $(get_build_dir intel-ucode)/intel-ucode $PKG_BUILD/external-firmware
  elif [ "$TARGET_ARCH" = "arm" -a "$DEVICE" = "iMX6" ]; then
      mkdir -p $PKG_BUILD/external-firmware
        cp -a $(get_build_dir kernel-firmware)/.copied-firmware/imx $PKG_BUILD/external-firmware
  fi

  if [ -d $PKG_BUILD/external-firmware/ ]; then
    FW_LIST="$(find $PKG_BUILD/external-firmware \( -type f -o -type l \) \( -iname '*.bin' -o -iname '*.fw' -o -path '*/intel-ucode/*' \) | sed 's|.*external-firmware/||' | sort | xargs)"
    sed -i "s|CONFIG_EXTRA_FIRMWARE=.*|CONFIG_EXTRA_FIRMWARE=\"${FW_LIST}\"|" $PKG_BUILD/.config
    sed -i -e "/CONFIG_EXTRA_FIRMWARE_DIR/d" -e "/CONFIG_EXTRA_FIRMWARE=.../a CONFIG_EXTRA_FIRMWARE_DIR=\"external-firmware\"" $PKG_BUILD/.config
  fi

  if [ "$DEVICE" = "Switch" ]; then
    kernel_make olddefconfig
    kernel_make prepare
    kernel_make modules_prepare
  else
    kernel_make olddefconfig
  fi

  # regdb (backward compatability with pre-4.15 kernels)
  if grep -q ^CONFIG_CFG80211_INTERNAL_REGDB= $PKG_BUILD/.config ; then
    cp $(get_build_dir wireless-regdb)/db.txt $PKG_BUILD/net/wireless/db.txt
  fi
}

make_target() {
  # arm64 target does not support creating uImage.
  # Build Image first, then wrap it using u-boot's mkimage.
  if [[ "$TARGET_KERNEL_ARCH" = "arm64" && "$KERNEL_TARGET" = uImage* ]]; then
    if [ -z "$KERNEL_UIMAGE_LOADADDR" -o -z "$KERNEL_UIMAGE_ENTRYADDR" ]; then
      die "ERROR: KERNEL_UIMAGE_LOADADDR and KERNEL_UIMAGE_ENTRYADDR have to be set to build uImage - aborting"
    fi
    KERNEL_UIMAGE_TARGET="$KERNEL_TARGET"
    KERNEL_TARGET="${KERNEL_TARGET/uImage/Image}"
  fi
  
  if [ "$DEVICE" = "Switch" ]; then
     export KCFLAGS+="-Wno-error=sizeof-pointer-memaccess -Wno-error=missing-attributes -Wno-error=stringop-truncation -Wno-error=stringop-overflow= -Wno-error=address-of-packed-member -Wno-error=tautological-compare -Wno-error=packed-not-aligned"
  fi

  kernel_make TOOLCHAIN="$TOOLCHAIN" $KERNEL_TARGET $KERNEL_MAKE_EXTRACMD modules

  if [ "$PKG_BUILD_PERF" = "yes" ] ; then
    ( cd tools/perf

      # arch specific perf build args
      case "$TARGET_ARCH" in
        x86_64|i386)
          PERF_BUILD_ARGS="ARCH=x86"
          ;;
        aarch64)
          PERF_BUILD_ARGS="ARCH=arm64"
          ;;
        *)
          PERF_BUILD_ARGS="ARCH=$TARGET_ARCH"
          ;;
      esac

      WERROR=0 \
      NO_LIBPERL=1 \
      NO_LIBPYTHON=1 \
      NO_SLANG=1 \
      NO_GTK2=1 \
      NO_LIBNUMA=1 \
      NO_LIBAUDIT=1 \
      NO_LZMA=1 \
      NO_SDT=1 \
      CROSS_COMPILE="$TARGET_PREFIX" \
      JOBS="$CONCURRENCY_MAKE_LEVEL" \
        make $PERF_BUILD_ARGS
      mkdir -p $INSTALL/usr/bin
        cp perf $INSTALL/usr/bin
    )
  fi

  if [ -n "$KERNEL_UIMAGE_TARGET" ] ; then
    # determine compression used for kernel image
    KERNEL_UIMAGE_COMP=${KERNEL_UIMAGE_TARGET:7}
    KERNEL_UIMAGE_COMP=${KERNEL_UIMAGE_COMP:-none}

    # calculate new load address to make kernel Image unpack to memory area after compressed image
    if [ "$KERNEL_UIMAGE_COMP" != "none" ] ; then
      COMPRESSED_SIZE=$(stat -t "arch/$TARGET_KERNEL_ARCH/boot/$KERNEL_TARGET" | awk '{print $2}')
      # align to 1 MiB
      COMPRESSED_SIZE=$(( (($COMPRESSED_SIZE - 1 >> 20) + 1) << 20 ))
      PKG_KERNEL_UIMAGE_LOADADDR=$(printf '%X' "$(( $KERNEL_UIMAGE_LOADADDR + $COMPRESSED_SIZE ))")
      PKG_KERNEL_UIMAGE_ENTRYADDR=$(printf '%X' "$(( $KERNEL_UIMAGE_ENTRYADDR + $COMPRESSED_SIZE ))")
    else
      PKG_KERNEL_UIMAGE_LOADADDR=${KERNEL_UIMAGE_LOADADDR}
      PKG_KERNEL_UIMAGE_ENTRYADDR=${KERNEL_UIMAGE_ENTRYADDR}
    fi

    mkimage -A $TARGET_KERNEL_ARCH \
            -O linux \
            -T kernel \
            -C $KERNEL_UIMAGE_COMP \
            -a $PKG_KERNEL_UIMAGE_LOADADDR \
            -e $PKG_KERNEL_UIMAGE_ENTRYADDR \
            -d arch/$TARGET_KERNEL_ARCH/boot/$KERNEL_TARGET \
               arch/$TARGET_KERNEL_ARCH/boot/$KERNEL_UIMAGE_TARGET

    KERNEL_TARGET="${KERNEL_UIMAGE_TARGET}"
  fi
}

makeinstall_target() {
  mkdir -p $INSTALL/.image
  cp -p arch/${TARGET_KERNEL_ARCH}/boot/${KERNEL_TARGET} System.map $INSTALL/.image/

  kernel_make INSTALL_MOD_PATH=$INSTALL/$(get_kernel_overlay_dir) modules_install
  rm -f $INSTALL/$(get_kernel_overlay_dir)/lib/modules/*/build
  rm -f $INSTALL/$(get_kernel_overlay_dir)/lib/modules/*/source
    
  if [ "$BOOTLOADER" = "switch-bootloader" ]; then
    mkdir -p $INSTALL/usr/share/bootloader/boot/
    cp arch/arm64/boot/dts/tegra210-icosa.dtb $INSTALL/usr/share/bootloader/boot/
  fi

  if [ "$BOOTLOADER" = "u-boot" ]; then
    mkdir -p $INSTALL/usr/share/bootloader
    for dtb in arch/$TARGET_KERNEL_ARCH/boot/dts/*.dtb arch/$TARGET_KERNEL_ARCH/boot/dts/*/*.dtb; do
      if [ -f $dtb ]; then
        cp -v $dtb $INSTALL/usr/share/bootloader
      fi
    done
  elif [ "$BOOTLOADER" = "bcm2835-bootloader" ]; then
    mkdir -p $INSTALL/usr/share/bootloader/overlays

    # install platform dtbs, but remove upstream kernel dtbs (i.e. without downstream
    # drivers and decent USB support) as these are not required by LibreELEC
    if [ "$PROJECT" = "RPi" -a "$ARCH" = "aarch64" ]; then
      cp -p arch/$TARGET_KERNEL_ARCH/boot/dts/broadcom/*.dtb $INSTALL/usr/share/bootloader
    else
      cp -p arch/$TARGET_KERNEL_ARCH/boot/dts/*.dtb $INSTALL/usr/share/bootloader
    fi
    rm -f $INSTALL/usr/share/bootloader/bcm283*.dtb

    # install overlay dtbs
    for dtb in arch/$TARGET_KERNEL_ARCH/boot/dts/overlays/*.dtbo; do
      cp $dtb $INSTALL/usr/share/bootloader/overlays 2>/dev/null || :
    done
    cp -p arch/$TARGET_KERNEL_ARCH/boot/dts/overlays/README $INSTALL/usr/share/bootloader/overlays
  fi

  mkdir -p $INSTALL/$(get_full_firmware_dir)/
  # regdb and signature is now loaded as firmware by 4.15+
    if grep -q ^CONFIG_CFG80211_REQUIRE_SIGNED_REGDB= $PKG_BUILD/.config; then
      cp $(get_build_dir wireless-regdb)/regulatory.db{,.p7s} $INSTALL/$(get_full_firmware_dir)
    fi
}
