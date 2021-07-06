# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mpd"
PKG_VERSION="0.21.4"
PKG_SHA256="247112eabf1b818a4052db7f0f5917ab00831ebc60a1ec3bf1154da4dc16a5c7"
PKG_REV="107"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://www.musicpd.org"
PKG_URL="http://www.musicpd.org/download/mpd/${PKG_VERSION%.*}/mpd-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain alsa-lib avahi boost curl faad2 ffmpeg flac glib lame libcdio libiconv libid3tag \
                    libmad libmpdclient libsamplerate libvorbis libnfs libogg mpd-mpc opus pulseaudio samba yajl libgcrypt"
PKG_SECTION="service.multimedia"
PKG_SHORTDESC="Music Player Daemon (MPD): a free and open Music Player Server"
PKG_LONGDESC="Music Player Daemon ($PKG_VERSION) is a flexible and powerful server-side application for playing music"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="Music Player Daemon (MPD)"
PKG_ADDON_TYPE="xbmc.service"

PKG_MESON_OPTS_TARGET=" \
  -Dadplug=disabled \
  -Dalsa=enabled \
  -Dao=disabled \
  -Daudiofile=disabled \
  -Dbzip2=enabled \
  -Dcdio_paranoia=disabled \
  -Dchromaprint=disabled \
  -Dcue=true \
  -Dcurl=enabled \
  -Ddatabase=true \
  -Ddocumentation=false \
  -Ddsd=true \
  -Dexpat=enabled \
  -Dfaad=enabled \
  -Dffmpeg=enabled \
  -Dfifo=false \
  -Dflac=enabled \
  -Dfluidsynth=disabled \
  -Dgme=disabled \
  -Dhttpd=true \
  -Diconv=disabled \
  -Dicu=disabled \
  -Did3tag=enabled \
  -Dipv6=enabled \
  -Diso9660=enabled \
  -Djack=disabled \
  -Dlame=enabled \
  -Dlibmpdclient=enabled \
  -Dlibsamplerate=enabled \
  -Dlocal_socket=false \
  -Dmad=enabled \
  -Dmikmod=disabled \
  -Dmms=disabled \
  -Dmodplug=disabled \
  -Dmpcdec=disabled \
  -Dmpg123=disabled \
  -Dneighbor=false \
  -Dnfs=enabled \
  -Dopenal=disabled \
  -Dopus=enabled \
  -Doss=disabled \
  -Dpipe=true \
  -Dpulse=enabled \
  -Dqobuz=enabled \
  -Drecorder=false \
  -Dshine=disabled \
  -Dshout=disabled \
  -Dsidplay=disabled \
  -Dsmbclient=enabled \
  -Dsndfile=enabled \
  -Dsndio=disabled \
  -Dsolaris_output=disabled \
  -Dsoundcloud=enabled \
  -Dsoxr=enabled \
  -Dsqlite=enabled \
  -Dsyslog=disabled \
  -Dsystemd=disabled \
  -Dtest=false \
  -Dtidal=enabled \
  -Dtwolame=disabled \
  -Dupnp=disabled \
  -Dvorbis=enabled \
  -Dvorbisenc=enabled \
  -Dwave_encoder=true \
  -Dwavpack=disabled \
  -Dwebdav=enabled \
  -Dwildmidi=disabled \
  -Dyajl=enabled \
  -Dzeroconf=avahi \
  -Dzlib=enabled \
  -Dzzip=disabled"

pre_configure_target() {
  export LIBS="$LIBS -logg -lFLAC -ldl"
}

makeinstall_target() {
  :
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
  cp -P $PKG_BUILD/.$TARGET_NAME/mpd $ADDON_BUILD/$PKG_ADDON_ID/bin
  # copy mpd cli binary
  cp -P $(get_build_dir mpd-mpc)/.$TARGET_NAME/mpc $ADDON_BUILD/$PKG_ADDON_ID/bin

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib
  cp -p $(get_install_dir libmpdclient)/usr/lib/libmpdclient.so $ADDON_BUILD/$PKG_ADDON_ID/lib
  cp -p $(get_install_dir libmpdclient)/usr/lib/libmpdclient.so.2 $ADDON_BUILD/$PKG_ADDON_ID/lib
}
