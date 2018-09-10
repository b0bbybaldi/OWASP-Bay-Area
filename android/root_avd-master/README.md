
# Rooting the Android Studio AVDs

A quick guide on how to root Android Studio's Android AVDs (and required files!)

Required files can be found in this repository: <https://github.com/0xFireball/root_avd>

You need the Android SDK and fresh new AVD. For this guide we will call it `RootAVD`.

This was written and tested on a Nexus 5X AVD running Android 7.1 Nougat on an Ubuntu Linux host.
This method _should_ work with a similar setup (Android Nougat) for the forseeable future, though
future Android versions may complicate this process further.

1. Start emulator `$SDK_PATH/emulator/emulator` with args `-avd RootAVD -writable-system -selinux disabled -qemu -enable-kvm`
1. Wait for boot.
1. Restart `adbd` as root and remount system as writable: `adb root && adb remount`
1. Install `Superuser.apk`: `adb install SuperSU/common/Superuser.apk`
1. Push `su` and update permissions: you will have to pick the corresponding architecture `$ARCH`. `adb push SuperSU/$ARCH/su /system/xbin/su`, then update permissions: `adb shell  chmod 0755 /system/xbin/su`
1. Set SELinux Permissive: `adb shell setenforce 0`
1. Install SuperSU's `su` to system: `adb shell su --install`
1. Run SuperSU's `su` as daemon. `adb shell su --daemon&`
1. Finally, open the SuperSU app on the device, and it will tell you the `su` binary needs to be updated. Accept and use normal installation.
1. Installation will fail. Don't reboot, just move on. It will still work.
1. Congratulations! You now have a rooted AVD with SuperSU.

**TIP: Superuser may not always persist after reboot, to fix:**
1. From a root shell, start `su --daemon&`
1. Root should now work.
1. Optional: Look for the temporary emulator system image; you can back this up and use it as a patched system.
