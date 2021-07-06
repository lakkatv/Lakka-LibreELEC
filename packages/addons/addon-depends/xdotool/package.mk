################################################################################
#      This file is part of LibreELEC - https://libreelec.tv
#      Copyright (C) 2009-2015 Stephan Raue (stephan@openelec.tv)
#      Copyright (C) 2016-present Team LibreELEC
#
#  LibreELEC is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  LibreELEC is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with LibreELEC.  If not, see <http://www.gnu.org/licenses/>.
################################################################################

PKG_NAME="xdotool"
PKG_VERSION="3.20160805.1"
#PKG_SHA256="e7b42c8b1d391970e1c1009b256033f30e57d8e0a2a3de229fd61ecfc27baf67"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://github.com/jordansissel/xdotool"
PKG_URL="https://github.com/jordansissel/xdotool/releases/download/v${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain libXinerama libXtst"
PKG_SECTION="x11/app"
PKG_SHORTDESC="This tool lets you simulate keyboard input and mouse activity, move and resize windows, etc."
PKG_LONGDESC="This tool lets you simulate keyboard input and mouse activity, move and resize windows, etc."
PKG_TOOLCHAIN="make"

pre_configure_target() {
  LDFLAGS="$LDFLAGS -lXext"
}

make_target() {
  make
}

makeinstall_target() {
  mkdir -p $INSTALL/usr/{lib,bin}
  cp xdotool $INSTALL/usr/bin
  cp libxdo* $INSTALL/usr/lib
  cp libxdo* ${TOOLCHAIN}/aarch64-libreelec-linux-gnueabi/sysroot/usr/lib/
}
