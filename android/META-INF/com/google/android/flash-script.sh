##########################################################################################
#
# Xposed framework installer zip.
#
# This script installs the Xposed framework files to the system partition.
# The Xposed Installer app is needed as well to manage the installed modules.
#
##########################################################################################

grep_prop() {
  REGEX="s/^$1=//p"
  shift
  FILES=$@
  if [ -z "$FILES" ]; then
    FILES=$PREFIX/system/build.prop
  fi
  cat $FILES 2>/dev/null | sed -n $REGEX | head -n 1
}

android_version() {
  case $1 in
    15) echo '4.0 / SDK'$1;;
    16) echo '4.1 / SDK'$1;;
    17) echo '4.2 / SDK'$1;;
    18) echo '4.3 / SDK'$1;;
    19) echo '4.4 / SDK'$1;;
    21) echo '5.0 / SDK'$1;;
    22) echo '5.1 / SDK'$1;;
    23) echo '6.0 / SDK'$1;;
    24) echo '7.0 / SDK'$1;;
    25) echo '7.1 / SDK'$1;;
    26) echo '8.0 / SDK'$1;;
    27) echo '8.1 / SDK'$1;;
    *)  echo 'SDK'$1;;
  esac
}

cp_perm() {
  cp -f $1 $2 || exit 1
  set_perm $2 $3 $4 $5 $6
}

set_perm() {
  chown $2:$3 $1 || exit 1
  chmod $4 $1 || exit 1
  if [ "$5" ]; then
    chcon $5 $1 2>/dev/null
  else
    chcon 'u:object_r:system_file:s0' $1 2>/dev/null
  fi
}

install_nobackup() {
  SOURCE=./$1
  TARGET="${PREFIX}${1}"
  cp_perm $SOURCE $TARGET $2 $3 $4 $5
}

install_and_link() {
  SOURCE="./${1}_xposed"
  TARGET="${PREFIX}${1}"
  LINK_TARGET="${1}_xposed"
  XPOSED="${PREFIX}${1}_xposed"
  BACKUP="${PREFIX}${1}_original"
  if [ ! -f $SOURCE ]; then
    return
  fi
  cp_perm $SOURCE $XPOSED $2 $3 $4 $5
  if [ ! -f $BACKUP ]; then
    mv $TARGET $BACKUP || exit 1
    ln -s $LINK_TARGET $TARGET || exit 1
    chcon -h 'u:object_r:system_file:s0' $TARGET 2>/dev/null
  fi
}

install_overwrite() {
  SOURCE=./$1
  TARGET="${PREFIX}${1}"
  if [ ! -f $SOURCE ]; then
    return
  fi
  BACKUP="${PREFIX}${1}.orig"
  NO_ORIG="${PREFIX}${1}.no_orig"
  if [ ! -f $TARGET ]; then
    touch $NO_ORIG || exit 1
    set_perm $NO_ORIG 0 0 600
  elif [ -f $BACKUP ]; then
    rm -f $TARGET
    gzip $BACKUP || exit 1
    set_perm "${BACKUP}.gz" 0 0 600
  elif [ ! -f "${BACKUP}.gz" -a ! -f $NO_ORIG ]; then
    mv $TARGET $BACKUP || exit 1
    gzip $BACKUP || exit 1
    set_perm "${BACKUP}.gz" 0 0 600
  fi
  cp_perm $SOURCE $TARGET $2 $3 $4 $5
}

##########################################################################################

echo "************************************"
echo " Xposed Framework installer zip"
echo "************************************"

if [ ! -f "system/xposed.prop" ]; then
  echo "! Failed: Extracted file system/xposed.prop not found!"
  exit 1
fi

echo "- Mounting /system and /vendor read-write"
SYSTEM_ROOT_IMAGE=$(grep_prop ro.build.system_root_image /default.prop /system/build.prop)
if [ "$SYSTEM_ROOT_IMAGE" = "true" ]; then
  if [ -d /system_root ]; then
    # Popular rooting tools create /system_root. /system might be a symlink, so remount /system_root as well.
    mount /system_root >/dev/null 2>&1
    mount -o remount,rw /system_root >/dev/null 2>&1
  else
    # ... but that doesn't exist on stock images.
    # /system is part of the root directory in that case, so try to remount it.
    mount / >/dev/null 2>&1
    mount -o remount,rw / >/dev/null 2>&1
  fi
fi
mount /system >/dev/null 2>&1
mount -o remount,rw /system
mount /vendor >/dev/null 2>&1
mount -o remount,rw /vendor >/dev/null 2>&1

PREFIX=
if [ "$SYSTEM_ROOT_IMAGE" = "true" -a -f /twres/twrp -a -f /system/system/build.prop ]; then
  # TWRP might mount the full system partion to /system, so files are actually in /system/system.
  PREFIX=/system
fi

# Check if build.prop is accessible now.
if [ ! -f $PREFIX/system/build.prop ]; then
  echo "! Failed: /system could not be mounted!"
  exit 1
fi

echo "- Checking environment"
API=$(grep_prop ro.build.version.sdk)
APINAME=$(android_version $API)
ABI=$(grep_prop ro.product.cpu.abi | cut -c-3)
ABI2=$(grep_prop ro.product.cpu.abi2 | cut -c-3)
ABILONG=$(grep_prop ro.product.cpu.abi)

XVERSION=$(grep_prop version system/xposed.prop)
XARCH=$(grep_prop arch system/xposed.prop)
XMINSDK=$(grep_prop minsdk system/xposed.prop)
XMAXSDK=$(grep_prop maxsdk system/xposed.prop)

XEXPECTEDSDK=$(android_version $XMINSDK)
if [ "$XMINSDK" != "$XMAXSDK" ]; then
  XEXPECTEDSDK=$XEXPECTEDSDK' - '$(android_version $XMAXSDK)
fi

ARCH=arm
IS64BIT=
if [ "$ABI" = "x86" ]; then ARCH=x86; fi;
if [ "$ABI2" = "x86" ]; then ARCH=x86; fi;
if [ "$API" -ge "21" ]; then
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; IS64BIT=1; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; IS64BIT=1; fi;
fi

# echo "DBG [$API] [$ABI] [$ABI2] [$ABILONG] [$ARCH] [$XARCH] [$XMINSDK] [$XMAXSDK] [$XVERSION]"

echo "  Xposed version:  $XVERSION"
echo "  Android version: $APINAME"
echo "  Platform:        $ARCH"

XVALID=
if [ "$ARCH" = "$XARCH" ]; then
  if [ "$API" -ge "$XMINSDK" ]; then
    if [ "$API" -le "$XMAXSDK" ]; then
      XVALID=1
    else
      echo "! Wrong Android version!"
      echo "! This file is for: $XEXPECTEDSDK"
    fi
  else
    echo "! Wrong Android version!"
    echo "! This file is for: $XEXPECTEDSDK"
  fi
else
  echo "! Wrong platform!"
  echo "! This file is for: $XARCH"
fi

if [ -z $XVALID ]; then
  echo "! Please download the correct package"
  echo "! for your platform/ROM!"
  exit 1
fi

echo "- Placing files"
install_nobackup /system/xposed.prop                      0    0 0644
install_nobackup /system/framework/XposedBridge.jar       0    0 0644

install_and_link  /system/bin/app_process32               0 2000 0755 u:object_r:zygote_exec:s0
install_overwrite /system/bin/dex2oat                     0 2000 0755 u:object_r:dex2oat_exec:s0
install_overwrite /system/bin/dexdiag                     0 2000 0755
install_overwrite /system/bin/dexlist                     0 2000 0755
install_overwrite /system/bin/dexoptanalyzer              0 2000 0755 u:object_r:dexoptanalyzer_exec:s0
install_overwrite /system/bin/oatdump                     0 2000 0755
install_overwrite /system/bin/patchoat                    0 2000 0755 u:object_r:dex2oat_exec:s0
install_overwrite /system/bin/profman                     0 2000 0755 u:object_r:profman_exec:s0

install_overwrite /system/lib/libart.so                   0    0 0644
install_overwrite /system/lib/libart-compiler.so          0    0 0644
install_overwrite /system/lib/libart-dexlayout.so         0    0 0644
install_overwrite /system/lib/libart-disassembler.so      0    0 0644
install_overwrite /system/lib/libsigchain.so              0    0 0644
install_overwrite /system/lib/libopenjdkjvm.so            0    0 0644
install_overwrite /system/lib/libopenjdkjvmti.so          0    0 0644
install_nobackup  /system/lib/libxposed_art.so            0    0 0644
if [ $IS64BIT ]; then
  install_and_link  /system/bin/app_process64             0 2000 0755 u:object_r:zygote_exec:s0
  install_overwrite /system/lib64/libart.so               0    0 0644
  install_overwrite /system/lib64/libart-compiler.so      0    0 0644
  install_overwrite /system/lib64/libart-dexlayout.so     0    0 0644
  install_overwrite /system/lib64/libart-disassembler.so  0    0 0644
  install_overwrite /system/lib64/libsigchain.so          0    0 0644
  install_overwrite /system/lib64/libopenjdkjvm.so        0    0 0644
  install_overwrite /system/lib64/libopenjdkjvmti.so      0    0 0644
  install_nobackup  /system/lib64/libxposed_art.so        0    0 0644
fi

if [ "$API" -ge "22" -a "$API" -le "23" ]; then
  find $PREFIX/system $PREFIX/vendor -type f -name '*.odex.gz' 2>/dev/null | while read f; do mv "$f" "$f.xposed"; done
fi

echo "- Done"
echo " "
echo "************************************"
echo "The first boot will take longer than"
echo "usual, please wait a few minutes."
echo "************************************"
echo " "

exit 0
