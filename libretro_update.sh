#!/bin/bash
LR_PKG_PATH="packages/libretro"
usage()
{
  echo ""
  echo "$0 <--all|--used|--packages pkg1 [pkg2] ...>"
  echo ""
  echo "Updates PKG_VERSION in package.mk of libretro packages to latest."
  echo ""
  echo "Parameters:"
  echo " -a --all                 Update all libretro packages"
  echo " -u --used                Update only libretro packages used by Lakka"
  echo " -p list --packages list  Update listed libretro packages"
  echo ""
}

[ "$1" == "" ] && { usage ; exit ; }

case $1 in
  -a | --all )
    # Get list of all libretro packages
    PACKAGES_ALL=`ls $LR_PKG_PATH`
    echo "Checking all libretro packages:"
    ;;
  -u | --used )
    # Get list of cores, which are used with Lakka:
    OPTIONS_FILE="distributions/Lakka/options"
    [ -f "$OPTIONS_FILE" ] && source "$OPTIONS_FILE" || { echo "$OPTIONS_FILE: not found! Aborting." ; exit 1 ; }
    [ -z "$LIBRETRO_CORES" ] && { echo "LIBRETRO_CORES: empty. Aborting!" ; exit 1 ; }
    # List of core retroarch packages
    RA_PACKAGES="retroarch retroarch-assets retroarch-joypad-autoconfig retroarch-overlays libretro-database core-info glsl-shaders"
    # List of cores used by specific projects not included in LIBRETRO_CORES.
    # This needs to be updated manually in case packages/lakka/*/package.mk
    # PKG_DEPENDS_TARGET includes a libretro core/package not included above.
    # PKG_DEPENDS_TARGET often includes also non-libretro packages, hence
    # not pulled from individual project-package files.
    ADDITIONAL_PACKAGES="beetle-bsnes bsnes beetle-psx bsnes-mercury"
    # List of all libretro packages to update:
    PACKAGES_ALL="$RA_PACKAGES $ADDITIONAL_PACKAGES $LIBRETRO_CORES"
    echo "Checking only libretro packages used by Lakka:"
    ;;
  -p | --packages )
    PACKAGES_ALL=""
    x="$1"
    shift
    v="$@"
    [ "$v" == "" ] && { echo "Error: You must provide name(s) of package(s) after $x" ; exit 1 ; }
    for a in $v ; do
      if [ -f $LR_PKG_PATH/$a/package.mk ] ; then
        PACKAGES_ALL="$PACKAGES_ALL $a"
      else
        echo "Warning: $a is not a libretro package - skipping."
      fi
    done
    [ "$PACKAGES_ALL" == "" ] && { echo "No valid packages given! Aborting." ; exit 1 ; }
    echo "Checking following packages:$PACKAGES_ALL"
    ;;
  * )
    usage
    echo "Unknown parameter: $1"
    exit 1
    ;;
esac
declare -i i=0
for p in $PACKAGES_ALL
do
  f=$LR_PKG_PATH/$p/package.mk
  if [ ! -f "$f" ] ; then
    echo "$f: not found! Skipping."
    continue
  fi
  PKG_VERSION=`cat $f | sed -En "s/PKG_VERSION=\"(.*)\"/\1/p"`
  PKG_SITE=`cat $f | sed -En "s/PKG_SITE=\"(.*)\"/\1/p"`
  PKG_NAME=`cat $f | sed -En "s/PKG_NAME=\"(.*)\"/\1/p"`
  if [ -z "$PKG_VERSION" ] || [ -z "$PKG_SITE" ] ; then
    echo "$f: does not have PKG_VERSION or PKG_SITE"
    echo "PKG_VERSION: $PKG_VERSION"
    echo "PKG_SITE: $PKG_SITE"
    echo "Skipping update."
    continue
  fi
  UPS_VERSION=`git ls-remote $PKG_SITE | grep HEAD | awk '{ print substr($1,1,7) }'`
  if [ "$UPS_VERSION" == "$PKG_VERSION" ]; then
    echo "$PKG_NAME is up to date ($UPS_VERSION)"
  else
    i+=1
    echo "$PKG_NAME updated from $PKG_VERSION to $UPS_VERSION"
    sed -i "s/$PKG_VERSION/$UPS_VERSION/" $f
  fi
done
echo "$i package(s) updated."
