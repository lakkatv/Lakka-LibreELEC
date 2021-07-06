# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="sapphire"
PKG_VERSION="7.1"
PKG_SHA256="24c662c45c581f8fe395d1cdcd6e1dca3db9e0eb590433f39de6037b2d4c5764"
PKG_REV="105"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="https://libreelec.tv"
PKG_URL="http://www.rtr.ca/sapphire_remote/$PKG_NAME-$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain linux bash"
PKG_SECTION="driver.remote"
PKG_SHORTDESC="A Linux driver to add support for sapphire remotes"
PKG_LONGDESC="A Linux driver to add support for sapphire remotes"
PKG_TOOLCHAIN="manual"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Sapphire Remote Driver"
PKG_ADDON_TYPE="xbmc.service"
PKG_IS_KERNEL_PKG="yes"

if [ -f $SYSROOT_PREFIX/usr/include/linux/input-event-codes.h ]; then
  INPUT_H="$SYSROOT_PREFIX/usr/include/linux/input-event-codes.h"
else
  INPUT_H="$SYSROOT_PREFIX/usr/include/linux/input.h"
fi

pre_make_target() {
  unset LDFLAGS
}

make_target() {
  kernel_make -C $(kernel_path) M=$(pwd) modules

  make INPUT_H=$INPUT_H \
       sapphire_keymap.sh
}

post_make_target() {
  sed -i -e 's|modprobe sapphire|insmod /storage/.kodi/addons/driver.remote.sapphire/lib/sapphire.ko|' \
         -e 's|/etc/sapphire.keymap|/storage/.kodi/userdata/addon_data/driver.remote.sapphire/sapphire.keymap|' \
         -e 's|/usr/local/bin/sapphire_keymap.sh|/storage/.kodi/addons/driver.remote.sapphire/bin/sapphire_keymap.sh|' \
         -e 's|\&\& /usr/local/bin/sapphire_keymap.sh|\&\& /storage/.kodi/addons/driver.remote.sapphire/bin/sapphire_keymap.sh /storage/.kodi/userdata/addon_data/driver.remote.sapphire/sapphire.keymap|' \
         sapphire_startup.sh

  sed -i -e 's|\#\!/bin/bash|\#\!/storage/.kodi/addons/driver.remote.sapphire/bin/bash|' \
         sapphire_startup.sh sapphire_keymap.sh
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib/
    cp $PKG_BUILD/*.ko $ADDON_BUILD/$PKG_ADDON_ID/lib

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/etc
    cp $PKG_BUILD/keymap.default $ADDON_BUILD/$PKG_ADDON_ID/etc

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin/
    cp $PKG_BUILD/sapphire_startup.sh $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp $PKG_BUILD/sapphire_keymap.sh $ADDON_BUILD/$PKG_ADDON_ID/bin

  # bash
    cp $(get_install_dir bash)/usr/bin/bash $ADDON_BUILD/$PKG_ADDON_ID/bin
}
