# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="emby"
PKG_VERSION="3.5.3.0"
PKG_SHA256="f25abb6d34f888c467db561ad333a222626febdc69b6353de86c04848753210c"
PKG_REV="124"
PKG_ARCH="any"
PKG_LICENSE="OSS"
PKG_SITE="http://emby.media"
PKG_URL="https://github.com/MediaBrowser/Emby.Releases/releases/download/$PKG_VERSION/embyserver-netcore_$PKG_VERSION.zip"
PKG_SOURCE_DIR="system"
PKG_DEPENDS_TARGET="toolchain imagemagick"
PKG_SECTION="service"
PKG_SHORTDESC="Emby Server: a personal media server"
PKG_LONGDESC="Emby Server ($PKG_VERSION) brings your home videos, music, and photos together, automatically converting and streaming your media on-the-fly to any device"
PKG_TOOLCHAIN="manual"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Emby Server"
PKG_ADDON_TYPE="xbmc.service"
PKG_ADDON_REQUIRES="tools.ffmpeg-tools:0.0.0 tools.dotnet-runtime:0.0.0"
PKG_MAINTAINER="Anton Voyl (awiouy)"

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/emby
  cp -r $PKG_BUILD/* \
        -d $ADDON_BUILD/$PKG_ADDON_ID/emby

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib
  cp -L $(get_install_dir imagemagick)/usr/lib/libMagickCore-7.Q16HDRI.so.? \
        $ADDON_BUILD/$PKG_ADDON_ID/lib/
  cp -L $(get_install_dir imagemagick)/usr/lib/libMagickWand-7.Q16HDRI.so \
        $ADDON_BUILD/$PKG_ADDON_ID/lib/CORE_RL_Wand_.so
}
