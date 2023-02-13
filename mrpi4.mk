#
# Copyright 2023 Andrei Makeev
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)

PRODUCT_NAME := mrpi4
PRODUCT_DEVICE := mrpi4
PRODUCT_BRAND := mrpi
PRODUCT_MANUFACTURER := Raspberry Pi
PRODUCT_MODEL := Raspberry Pi 4

TARGET_BOARD_PLATFORM := bcm2711

# Extra rpi images
TARGET_RPI_FULL_DISK_IMAGE_NAME := full_disk
TARGET_RPI_PROVISIONING_DISK_IMAGE_NAME := provisioning_disk
TARGET_RPIBOOT_IMAGE_NAME := rpiboot
TARGET_RPIMISC_IMAGE_NAME := rpimisc
PRODUCT_CUSTOM_FAT_IMAGES := $(TARGET_RPIBOOT_IMAGE_NAME) $(TARGET_RPIMISC_IMAGE_NAME)
TARGET_COPY_OUT_RPIBOOT := $(TARGET_RPIBOOT_IMAGE_NAME)
TARGET_COPY_OUT_RPIMISC := $(TARGET_RPIMISC_IMAGE_NAME)

##
# Building U-Boot
##

# Where do we have u-boot checked out
TARGET_U_BOOT_SOURCE := external/u-boot
# Which u-boot config to use
TARGET_U_BOOT_CONFIG := $(LOCAL_PATH)/uboot_config/uboot_config
# Which u-boot build script to use
TARGET_U_BOOT_SCRIPT := $(LOCAL_PATH)/uboot_config/uboot_script
# Which u-boot build environment to use
TARGET_U_BOOT_ENV := $(LOCAL_PATH)/uboot_config/uboot_env
# Which image among all the images u-boot provides we want
TARGET_U_BOOT_IMAGE := u-boot.bin
# Name of boot script image to build
TARGET_U_BOOT_SCRIPT_IMAGE := boot.scr.uimg
# Name of environment image to build
TARGET_U_BOOT_ENV_IMAGE := uboot.env
# CPU architecture to build u-boot for
TARGET_U_BOOT_CPU_ARCH := aarch64
# Cross compile triplet to use for building u-boot
TARGET_U_BOOT_CROSS_COMPILE := $(TARGET_U_BOOT_CPU_ARCH)-linux-android
# Include the makefile for U-boot
include $(LOCAL_PATH)/AndroidUBoot.mk

##
# Copying files to raspberry pi boot images
##

# U-Boot artefacts
PRODUCT_COPY_FILES += \
    $(U-BOOT_INTM_IMG):$(TARGET_COPY_OUT_RPIBOOT)/$(TARGET_U_BOOT_IMAGE) \
    $(U-BOOT_INTM_SCRIPT_IMG):$(TARGET_COPY_OUT_RPIBOOT)/$(TARGET_U_BOOT_SCRIPT_IMAGE) \
    $(U-BOOT_INTM_ENV_IMG):$(TARGET_COPY_OUT_RPIBOOT)/$(TARGET_U_BOOT_ENV_IMAGE) \
    $(LOCAL_PATH)/rpi_boot/config.txt:$(TARGET_COPY_OUT_RPIBOOT)/config.txt \
    $(LOCAL_PATH)/uboot_config/uEnv.txt:$(TARGET_COPY_OUT_RPIBOOT)/uEnv.txt

RPI_FIRMWARE_BOOT_DIR := device/raspberrypi/common/firmware/boot
# Raspberry Pi firmware files, except for *.img files (kernel images)
PRODUCT_COPY_FILES += \
    $(foreach f,$(filter-out %.img,$(wildcard $(RPI_FIRMWARE_BOOT_DIR)/*.*)),$(f):$(TARGET_COPY_OUT_RPIBOOT)/$(notdir $(f)))

# Raspberry Pi device tree overlay files
PRODUCT_COPY_FILES += \
    $(foreach f,$(wildcard $(RPI_FIRMWARE_BOOT_DIR)/overlays/*.*),$(f):$(TARGET_COPY_OUT_RPIBOOT)/overlays/$(notdir $(f)))

# Boot partition selection config files for rpimisc
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/rpi_boot/autoboot.txt:$(TARGET_COPY_OUT_RPIMISC)/autoboot.txt

$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
