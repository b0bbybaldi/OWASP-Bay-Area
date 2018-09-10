#!/bin/sh
echo "Start your emulator with `emulator -avd NAMEOFX86A8.0 -writable-system -selinux disabled -wipe-data`"
adb root && adb remount
adb install root_avd-master/SuperSU/common/Superuser.apk
adb push root_avd-master/SuperSU/x86/su /system/xbin/su
adb shell chmod 0755 /system/xbin/su
adb shell setenforce 0
adb shell su --install
adb shell su --daemon&
//continue at http://www.andnixsh.com/2018/06/how-to-install-xposed-on-any-android.html
