# Appcircle _Wait for Android emulator_ component

Wait for Android emulator to boot

## Required Inputs

- `AC_TEST_DEVICE`: Test Device. Specifies device for test. If you use emulator other than Pixel_3a, you need to create it by yourself.
- `AC_TEST_ADB_ARGUMENTS`: ADB arguments for the device. You may add new arguments but don't change the default ones such as no-window.

## Optional Inputs

- `AC_TEST_ADB_WAIT_SECONDS`: Boot Timeout. Specifies the number of seconds the component must wait for the emulator to boot.
- `AC_APK_PATH`: APK Path. Optional full path of the apk file to install after the emulator boots.
