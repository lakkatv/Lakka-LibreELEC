# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

case "$ARCH" in
  "aarch64")
    PKG_NC_ARCH="arm64"
    PKG_SHA256="05875790fbfc487cefb04fc6ff6d9a3ade147f1ae554e859dca60ea6a3c232aa"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/65291ed8-e931-4605-9d5a-265928a835d0/1a15d18655c8b260170117e9bd1a1cb7/dotnet-runtime-3.1.5-linux-arm64.tar.gz"
    ;;
  "arm")
    PKG_NC_ARCH="arm"
    PKG_SHA256="5728786f517410f25c59799f443d0336129d6b1680fd40cb5b40202407949008"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/15132a5c-f0f4-4373-8b8b-b7e70834d899/cad479dda52359ad43956471274ec932/dotnet-runtime-3.1.5-linux-arm.tar.gz"
    ;;
  "x86_64")
    PKG_NC_ARCH="x64"
    PKG_SHA256="ae0a4e9a1e875b46d3201cdad2779572de1c12c0aae36688ae3c3978db319ff5"
    PKG_URL="https://download.visualstudio.microsoft.com/download/pr/d00eaeea-6d7b-4e73-9d96-c0234ed3b665/0d25d9d1aeaebdeef01d15370d5cd22b/dotnet-runtime-3.1.5-linux-x64.tar.gz"
    ;;
esac

PKG_NAME="dotnet-runtime"
PKG_VERSION="3.1.5"
PKG_REV="110"
PKG_ARCH="any"
PKG_LICENSE="MIT"
PKG_SITE="https://dotnet.github.io/"
PKG_DEPENDS_TARGET="toolchain curl curl3 krb5 lttng-ust"
PKG_SECTION="tools"
PKG_SHORTDESC=".NET Core Runtime"
PKG_LONGDESC=".NET Core Runtime ($PKG_VERSION) runs applications built with .NET Core, a cross-platform .NET implementation."
PKG_TOOLCHAIN="manual"

PKG_IS_ADDON="yes"
PKG_ADDON_NAME=".Net Core Runtime"
PKG_ADDON_TYPE="xbmc.python.script"
PKG_MAINTAINER="Anton Voyl (awiouy)"

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin
  cp -r $PKG_BUILD/* \
        $ADDON_BUILD/$PKG_ADDON_ID/bin

  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/libs
  cp -L $(get_install_dir curl3)/usr/lib/libcurl.so.? \
        $(get_install_dir krb5)/usr/lib/libcom_err.so.? \
        $(get_install_dir krb5)/usr/lib/libgssapi_krb5.so.? \
        $(get_install_dir krb5)/usr/lib/libk5crypto.so.? \
        $(get_install_dir krb5)/usr/lib/libkrb5.so.? \
        $(get_install_dir krb5)/usr/lib/libkrb5support.so.? \
        $(get_install_dir lttng-ust)/usr/lib/liblttng-ust.so.? \
        $(get_install_dir lttng-ust)/usr/lib/liblttng-ust-tracepoint.so.? \
        $ADDON_BUILD/$PKG_ADDON_ID/libs
}
