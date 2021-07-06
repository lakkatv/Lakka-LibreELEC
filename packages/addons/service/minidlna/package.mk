# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="minidlna"
PKG_VERSION="799e6cf505ec470b2bf0ae4118143380aa16b837"
PKG_SHA256="6d9d5a874381415b81dde80df30aa127ad732be341b37d73effb8a135454cbee"
PKG_VERSION_DATE="1.2.1+2018-05-04"
PKG_REV="101"
PKG_ARCH="any"
PKG_LICENSE="BSD-3c/GPLv2"
PKG_SITE="https://sourceforge.net/projects/minidlna/"
PKG_URL="http://repo.or.cz/minidlna.git/snapshot/$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain ffmpeg flac libexif libiconv libid3tag libjpeg-turbo libogg libvorbis sqlite"
PKG_SECTION="service"
PKG_SHORTDESC="MiniDLNA (ReadyMedia): a fully compliant DLNA/UPnP-AV server"
PKG_LONGDESC="MiniDLNA ($PKG_VERSION_DATE) (ReadyMedia) is a media server, with the aim of being fully compliant with DLNA/UPnP-AV clients."
PKG_TOOLCHAIN="autotools"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="MiniDLNA (ReadyMedia)"
PKG_ADDON_TYPE="xbmc.service"

PKG_CONFIGURE_OPTS_TARGET="--disable-static \
                           --disable-nls \
                           --without-libiconv-prefix \
                           --without-libintl-prefix \
                           --with-os-name="$DISTRONAME" \
                           --with-db-path="/storage/.kodi/userdata/addon_data/service.minidlna/db" \
                           --with-os-url="https://libreelec.tv""

pre_configure_target() {
  export LDFLAGS="$LDFLAGS -L$(get_install_dir ffmpeg)/usr/lib"
  export LIBS="$LIBS -lid3tag -lFLAC -logg -lz -lpthread -ldl -lm"
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
  cp -P $PKG_INSTALL/usr/sbin/minidlnad $ADDON_BUILD/$PKG_ADDON_ID/bin

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib
  cp -p $(get_install_dir libexif)/usr/lib/libexif.so.12 $ADDON_BUILD/$PKG_ADDON_ID/lib
}
