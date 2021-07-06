# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2016-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="system-tools"
PKG_VERSION="1.0"
PKG_REV="111"
PKG_ARCH="any"
PKG_LICENSE="GPL"
PKG_SITE="https://libreelec.tv"
PKG_URL=""
PKG_DEPENDS_TARGET="toolchain"
PKG_SECTION="virtual"
PKG_SHORTDESC="A bundle of system tools and programs"
PKG_LONGDESC="This bundle currently includes autossh, diffutils, dstat, dtach, efibootmgr, encfs, evtest, fdupes, file, getscancodes, hddtemp, hd-idle, hid_mapper, htop, i2c-tools, inotify-tools, jq, lm_sensors, lshw, mc, mrxvt, mtpfs, nmon, p7zip, patch, pv, screen, smartmontools, strace, stress-ng, unrar, usb-modeswitch and vim."

PKG_IS_ADDON="yes"
PKG_ADDON_NAME="System Tools"
PKG_ADDON_TYPE="xbmc.python.script"

PKG_DEPENDS_TARGET="toolchain \
                    autossh \
                    diffutils \
                    dstat \
                    dtach \
                    encfs \
                    evtest \
                    fdupes \
                    file \
                    getscancodes \
                    hddtemp \
                    hd-idle \
                    hid_mapper \
                    htop \
                    i2c-tools \
                    inotify-tools \
                    jq \
                    lm_sensors \
                    lshw \
                    mc \
                    mtpfs \
                    nmon \
                    p7zip \
                    patch \
                    pv \
                    screen \
                    smartmontools \
                    strace \
                    stress-ng \
                    unrar \
                    usb-modeswitch \
                    vim"

if [ "$TARGET_ARCH" = "x86_64" ]; then
  PKG_DEPENDS_TARGET="$PKG_DEPENDS_TARGET efibootmgr mrxvt"
fi

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/lib/
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/data/
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/bin/
    # autossh
    cp -P $(get_build_dir autossh)/.$TARGET_NAME/autossh $ADDON_BUILD/$PKG_ADDON_ID/bin

    # diffutils
    cp -P $(get_build_dir diffutils)/.$TARGET_NAME/src/cmp $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir diffutils)/.$TARGET_NAME/src/diff $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir diffutils)/.$TARGET_NAME/src/diff3 $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir diffutils)/.$TARGET_NAME/src/sdiff $ADDON_BUILD/$PKG_ADDON_ID/bin

    # dstat
    cp -P $(get_build_dir dstat)/dstat $ADDON_BUILD/$PKG_ADDON_ID/bin

    # dtach
    cp -P $(get_build_dir dtach)/.$TARGET_NAME/dtach $ADDON_BUILD/$PKG_ADDON_ID/bin

    # efibootmgr
    cp -P $(get_build_dir efibootmgr)/src/efibootmgr $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :

    # encfs
    cp -P $(get_build_dir encfs)/.$TARGET_NAME/encfs $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir encfs)/.$TARGET_NAME/encfsctl $ADDON_BUILD/$PKG_ADDON_ID/bin

    # evtest
    cp -P $(get_build_dir evtest)/.$TARGET_NAME/evtest $ADDON_BUILD/$PKG_ADDON_ID/bin

    # fdupes
    cp -P $(get_build_dir fdupes)/fdupes $ADDON_BUILD/$PKG_ADDON_ID/bin

    # file
    cp -P $(get_build_dir file)/.$TARGET_NAME/src/file $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir file)/.$TARGET_NAME/magic/magic.mgc $ADDON_BUILD/$PKG_ADDON_ID/data

    # getscancodes
    cp -P $(get_build_dir getscancodes)/getscancodes $ADDON_BUILD/$PKG_ADDON_ID/bin

    # hddtemp
    cp -P $(get_build_dir hddtemp)/.$TARGET_NAME/src/hddtemp $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir hddtemp)/hddtemp.db $ADDON_BUILD/$PKG_ADDON_ID/data

    # hd-idle
    cp -P $(get_build_dir hd-idle)/hd-idle $ADDON_BUILD/$PKG_ADDON_ID/bin

    # hid_mapper
    cp -P $(get_build_dir hid_mapper)/hid_mapper $ADDON_BUILD/$PKG_ADDON_ID/bin

    # htop
    cp -P $(get_install_dir htop)/usr/bin/htop $ADDON_BUILD/$PKG_ADDON_ID/bin

    # i2c-tools
    cp -P $(get_build_dir i2c-tools)/tools/i2cdetect $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir i2c-tools)/tools/i2cdump $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir i2c-tools)/tools/i2cget $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir i2c-tools)/tools/i2cset $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir i2c-tools)/py-smbus/build/lib.linux-*/smbus.so $ADDON_BUILD/$PKG_ADDON_ID/lib

    # inotify-tools
    cp -P $(get_build_dir inotify-tools)/.$TARGET_NAME/src/inotifywait $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir inotify-tools)/.$TARGET_NAME/src/inotifywatch $ADDON_BUILD/$PKG_ADDON_ID/bin

    # jq
    cp -P $(get_build_dir jq)/.$TARGET_NAME/jq $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_install_dir oniguruma)/usr/lib/libonig.so $ADDON_BUILD/$PKG_ADDON_ID/lib

    # lm_sensors
    cp -P $(get_build_dir lm_sensors)/prog/sensors/sensors $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :

    # lshw
    cp -P $(get_build_dir lshw)/src/lshw $ADDON_BUILD/$PKG_ADDON_ID/bin

    # mc
    cp -Pa $(get_install_dir mc)/usr/bin/* $ADDON_BUILD/$PKG_ADDON_ID/bin/
    cp -Pa $(get_install_dir mc)/storage/.kodi/addons/virtual.system-tools/* $ADDON_BUILD/$PKG_ADDON_ID

    # mrxvt
    cp -P $(get_build_dir mrxvt)/.$TARGET_NAME/src/mrxvt $ADDON_BUILD/$PKG_ADDON_ID/bin 2>/dev/null || :

    # mtpfs
    cp -P $(get_build_dir mtpfs)/.$TARGET_NAME/mtpfs $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # nmon
    cp -P $(get_build_dir nmon)/nmon $ADDON_BUILD/$PKG_ADDON_ID/bin/

    # p7zip
    cp -P $(get_build_dir p7zip)/bin/7z.so $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -PR $(get_build_dir p7zip)/bin/Codecs $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir p7zip)/bin/7z $ADDON_BUILD/$PKG_ADDON_ID/bin
    cp -P $(get_build_dir p7zip)/bin/7za $ADDON_BUILD/$PKG_ADDON_ID/bin

    # patch
    cp -P $(get_build_dir patch)/.$TARGET_NAME/src/patch $ADDON_BUILD/$PKG_ADDON_ID/bin

    # pv
    cp -P $(get_build_dir pv)/.$TARGET_NAME/pv $ADDON_BUILD/$PKG_ADDON_ID/bin

    # screen
    cp -P $(get_build_dir screen)/screen $ADDON_BUILD/$PKG_ADDON_ID/bin

    # smartmontools
    cp -P $(get_build_dir smartmontools)/.$TARGET_NAME/smartctl $ADDON_BUILD/$PKG_ADDON_ID/bin

    # strace
    cp -P $(get_build_dir strace)/.$TARGET_NAME/strace $ADDON_BUILD/$PKG_ADDON_ID/bin

    # stress-ng
    cp -P $(get_install_dir stress-ng)/usr/bin/stress-ng $ADDON_BUILD/$PKG_ADDON_ID/bin

    # unrar
    cp -P $(get_build_dir unrar)/unrar $ADDON_BUILD/$PKG_ADDON_ID/bin

    # usb-modeswitch
    cp -P $(get_build_dir usb-modeswitch)/usb_modeswitch $ADDON_BUILD/$PKG_ADDON_ID/bin

    # vim
    cp -P $(get_install_dir vim)/usr/bin/vim $ADDON_BUILD/$PKG_ADDON_ID/bin
}
