# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mariadb"
PKG_VERSION="10.3.14"
PKG_REV="103"
PKG_SHA256="ba1c94d92fc8ebdf9b8a1d1b93ed6aeeead33da507efbbd4afcf49f32023e054"
PKG_LICENSE="GPL2"
PKG_SITE="https://mariadb.org"
PKG_URL="https://downloads.mariadb.org/interstitial/${PKG_NAME}-${PKG_VERSION}/source/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host ncurses:host"
PKG_DEPENDS_TARGET="toolchain binutils bzip2 libaio libxml2 lzo ncurses openssl systemd zlib mariadb:host"
PKG_SHORTDESC="MariaDB is a community-developed fork of the MySQL."
PKG_LONGDESC="MariaDB (${PKG_VERSION}) is a fast SQL database server and a drop-in replacement for MySQL."
PKG_TOOLCHAIN="cmake"
PKG_BUILD_FLAGS="-gold -sysroot"

PKG_IS_ADDON="yes"
PKG_SECTION="service"
PKG_ADDON_NAME="MariaDB SQL database server"
PKG_ADDON_TYPE="xbmc.service"

configure_package() {
  PKG_CMAKE_OPTS_HOST=" \
    -DCMAKE_INSTALL_MESSAGE=NEVER \
    -DSTACK_DIRECTION=-1 \
    -DHAVE_IB_GCC_ATOMIC_BUILTINS=1 \
    -DCMAKE_CROSSCOMPILING=OFF \
    import_executables"

  PKG_CMAKE_OPTS_TARGET=" \
    -DCMAKE_INSTALL_MESSAGE=NEVER \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_CONFIG=mysql_release \
    -DFEATURE_SET=classic \
    -DSTACK_DIRECTION=1 \
    -DDISABLE_LIBMYSQLCLIENT_SYMBOL_VERSIONING=ON \
    -DCMAKE_CROSSCOMPILING=ON \
    -DIMPORT_EXECUTABLES=${PKG_BUILD}/.${HOST_NAME}/import_executables.cmake \
    -DWITHOUT_AWS_KEY_MANAGEMENT=ON \
    -DWITH_EXTRA_CHARSETS=complex \
    -DWITH_SSL=system \
    -DWITH_SSL=${SYSROOT_PREFIX}/usr \
    -DWITH_JEMALLOC=OFF \
    -DWITH_PCRE=bundled \
    -DWITH_ZLIB=bundled \
    -DWITH_EDITLINE=bundled \
    -DWITH_LIBEVENT=bundled \
    -DCONNECT_WITH_LIBXML2=bundled \
    -DSKIP_TESTS=ON \
    -DWITH_DEBUG=OFF \
    -DWITH_UNIT_TESTS=OFF \
    -DENABLE_DTRACE=OFF \
    -DSECURITY_HARDENED=OFF \
    -DWITH_EMBEDDED_SERVER=OFF \
    -DWITHOUT_SERVER=OFF \
    -DPLUGIN_AUTH_SOCKET=STATIC \
    -DDISABLE_SHARED=NO \
    -DENABLED_PROFILING=OFF \
    -DENABLE_STATIC_LIBS=OFF \
    -DMYSQL_UNIX_ADDR=/var/run/mysqld/mysqld.sock \
    -DWITH_SAFEMALLOC=OFF \
    -DWITHOUT_AUTH_EXAMPLES=ON"
}

make_host() {
  ninja ${NINJA_OPTS} import_executables
}

makeinstall_host() {
  :
}

post_makeinstall_target() {
  rm -rf "${PKG_INSTALL}/usr/mysql-test"
}

addon() {
  local ADDON="${ADDON_BUILD}/${PKG_ADDON_ID}"
  local MARIADB="${PKG_INSTALL}/usr"

  mkdir -p ${ADDON}/bin
  mkdir -p ${ADDON}/config

  cp ${MARIADB}/bin/mysql \
     ${MARIADB}/bin/mysqld \
     ${MARIADB}/bin/mysqladmin \
     ${MARIADB}/bin/mysqldump \
     ${MARIADB}/bin/mysql_secure_installation \
     ${MARIADB}/bin/my_print_defaults \
     ${MARIADB}/bin/resolveip \
     ${MARIADB}/scripts/mysql_install_db \
     ${ADDON}/bin

  cp -PR ${MARIADB}/share ${ADDON}
}
