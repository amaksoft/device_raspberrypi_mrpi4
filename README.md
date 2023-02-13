# device_raspberrypi_mrpi4
Device folder for Raspberry Pi AOSP


## Check out the sources
https://github.com/amaksoft/raspberrypi_local_manifest


## Build instructions
```
# Build a minimal bootable image that supports fastboot to flash the rest using it
$ source build/envsetup.sh && lunch mrpi4-eng && make rpiprovisionimage
```
## Flashing the provisioning image
The resuting ptovisioning image can be found in `out/target/product/mrpi4/`
You can flash it with Raspberry Pi imager https://www.raspberrypi.com/software/ or with dd, or with any other tool you like
