# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2015 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="proftpd"
PKG_VERSION="1.3.6"
PKG_SHA256="91ef74b143495d5ff97c4d4770c6804072a8c8eb1ad1ecc8cc541b40e152ecaf"
PKG_REV="102"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="http://www.proftpd.org/"
PKG_URL="https://github.com/proftpd/proftpd/archive/v$PKG_VERSION.tar.gz"
PKG_DEPENDS_TARGET="toolchain libcap openssl ncurses pcre whois"
PKG_SECTION="service"
PKG_SHORTDESC="ProFTPD: a FTP server for linux"
PKG_LONGDESC="ProFTPD ($PKG_VERSION): is a secure and configurable FTP server with SSL/TLS support"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="ProFTPD Server"
PKG_ADDON_TYPE="xbmc.service"

ADDON_DIR="/storage/.kodi/addons/service.proftpd"

PKG_CONFIGURE_OPTS_TARGET="--enable-static \
                           --enable-openssl \
                           --with-modules=mod_tls \
                           --enable-nls \
                           --localedir=$ADDON_DIR/locale \
                           --enable-sendfile \
                           --enable-facl \
                           --enable-autoshadow \
                           --enable-ctrls \
                           --enable-ipv6 \
                           --enable-nls \
                           --enable-pcre \
                           --enable-largefile"

pre_build_target() {
  mkdir -p $PKG_BUILD/.$TARGET_NAME
  cp -RP $PKG_BUILD/* $PKG_BUILD/.$TARGET_NAME
}

pre_configure_target() {
  export CFLAGS="$CFLAGS -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -I$PKG_BUILD/.$TARGET_NAME/include/"
  export LDFLAGS="$LDFLAGS -L$PKG_BUILD/.$TARGET_NAME/lib"
}

makeinstall_target() {
  : # nop
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp $PKG_BUILD/.$TARGET_NAME/proftpd   $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp $PKG_BUILD/.$TARGET_NAME/ftpwho  $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp $PKG_BUILD/.$TARGET_NAME/ftptop  $ADDON_BUILD/$PKG_ADDON_ID/bin

    cp $(get_build_dir whois)/mkpasswd $ADDON_BUILD/$PKG_ADDON_ID/bin

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/locale
    cp $PKG_BUILD/.$TARGET_NAME/locale/* $ADDON_BUILD/$PKG_ADDON_ID/locale
}
