#!/bin/sh
echo "Start your emulator with 'emulator -avd NAMEOFX86A8.0 -writable-system -selinux disabled -wipe-data'"
adb root && adb remount
adb install SuperSU\ v2.79.apk
adb push root_avd-master/SuperSU/x86/su /system/xbin/su
adb shell chmod 0755 /system/xbin/su
adb shell setenforce 0
adb shell su --install
adb shell su --daemon&
adb push busybox /data/busybox
# adb shell "mount -o remount,rw /system && mv /data/busybox /system/bin/busybox && chmod 755 /system/bin/busybox && /system/bin/busybox --install /system/bin"
adb shell chmod 755 /data/busybox
adb shell 'sh -c "./data/busybox --install /data"'
adb shell 'sh -c "mkdir /sdcard/xposed"'
adb push xposed.zip /sdcard/xposed/xposed.zip
adb shell chmod 0755 /sdcard/xposed
adb shell 'sh -c "./data/unzip /sdcard/xposed/xposed.zip -d /sdcard/xposed/"'
adb shell 'sh -c "cp /sdcard/xposed/xposed/META-INF/com/google/android/*.* /sdcard/xposed/xposed/"'
echo "Now start the su ./sdcard/xposed/xposed/Flash-Script.sh as ADB shell after installing SUperSU"
echo "Next, restart emulator"
echo "Next, adb install XposedInstaller_3.1.5.apk"
echo "Next, run installer and then adb reboot"
# adb shell 'sh -c "su ./sdcard/xposed/xposed/Flash-Script.sh"'
