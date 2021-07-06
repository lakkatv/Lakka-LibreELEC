# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="multimedia-tools"
PKG_VERSION="1.0"
PKG_REV="109"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="virtual"
PKG_SHORTDESC="A bundle of multimedia tools and programs"
PKG_LONGDESC="This bundle currently includes alsamixer, mediainfo, mesa-demos, mpg123, opencaster, squeezelite, tsdecrypt and tstools."

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Multimedia Tools"
PKG_ADDON_TYPE="xbmc.python.script"


PKG_DEPENDS_TARGET="toolchain \
                    alsa-utils \
                    mediainfo \
                    mpg123 \
                    opencaster \
                    squeezelite \
                    tsdecrypt \
                    tstools"

if [ "$TARGET_ARCH" = "x86_64" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET mesa-demos"
fi

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin/
    # alsamixer
    cp -P $(get_build_dir alsa-utils)/.$TARGET_NAME/alsamixer/alsamixer $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # mediainfo
    cp -P $(get_build_dir mediainfo)/Project/GNU/CLI/mediainfo $ADDON_BUILD/$PKG_ADDON_ID/bin

    # mesa-demos
    cp -P $(get_build_dir mesa-demos)/.$TARGET_NAME/src/xdemos/glxdemo $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :
    cp -P $(get_build_dir mesa-demos)/.$TARGET_NAME/src/xdemos/glxgears $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :
    cp -P $(get_build_dir mesa-demos)/.$TARGET_NAME/src/xdemos/glxinfo $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :

    # mpg123
    cp -P $(get_install_dir mpg123)/usr/bin/* $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # opencaster
    cp -P $(get_install_dir opencaster)/* $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # squeezelite
    cp -P $(get_build_dir squeezelite)/squeezelite $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # tsdecrypt
    cp -P $(get_build_dir tsdecrypt)/tsdecrypt $ADDON_BUILD/$PKG_ADDON_ID/bin

    # tstools
    cp -P $(get_build_dir tstools)/bin/* $ADDON_BUILD/$PKG_ADDON_ID/bin/
}
