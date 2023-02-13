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

RPI_BOOT_IMAGE_LOCAL_PATH := $(call my-dir)

# TODO: deduplicate this code!

RPI_BOOT_IMAGE_HOST_MCOPY := $(HOST_OUT_EXECUTABLES)/mcopy
RPI_BOOT_IMAGE_HOST_MKFS_FAT := $(HOST_OUT_EXECUTABLES)/mkfs.fat
RPI_BOOT_IMAGE_HOST_SFDISK := $(HOST_OUT_EXECUTABLES)/sfdisk
RPI_BOOT_IMAGE_HOST_FALLOCATE := $(HOST_OUT_EXECUTABLES)/fallocate

RPI_BOOT_IMAGE_HOST_ENVSUBST := prebuilts/gettext/$(HOST_PREBUILT_TAG)/bin/envsubst

RPI_BOOT_DISK_TOOLS := $(HOST_OUT_EXECUTABLES)/mcopy $(HOST_OUT_EXECUTABLES)/mkfs.fat $(HOST_OUT_EXECUTABLES)/sfdisk $(HOST_OUT_EXECUTABLES)/fallocate

INSTALLED_RPIBOOTIMAGE_TARGET := $(PRODUCT_OUT)/custom_fw/$(TARGET_RPIBOOT_IMAGE_NAME).img
INSTALLED_RPIMISCIMAGE_TARGET := $(PRODUCT_OUT)/custom_fw/$(TARGET_RPIMISC_IMAGE_NAME).img

.PHONY: rpibootimage rpimiscimage
rpibootimage: $(INSTALLED_RPIBOOTIMAGE_TARGET)
rpimiscimage: $(INSTALLED_RPIMISCIMAGE_TARGET)

# Get second part after spliting by colon each entry in PRODUCT_COPY_FILES (path to copy to)
# Filter out those starting with value TARGET_COPY_OUT_RPIBOOT
# Prepend PRODUCT_OUT to each
# As a result we will get the full path to each file that will end up in PRODUCT_OUT/TARGET_COPY_OUT_RPIBOOT i.e images to copy into the image
INSTALLED_FILES_RPIBOOT := $(addprefix $(PRODUCT_OUT)/,$(filter $(TARGET_COPY_OUT_RPIBOOT)/%, $(foreach cf,$(PRODUCT_COPY_FILES), $(call word-colon,2,$(cf)))))
INSTALLED_FILES_RPIMISC := $(addprefix $(PRODUCT_OUT)/,$(filter $(TARGET_COPY_OUT_RPIMISC)/%, $(foreach cf,$(PRODUCT_COPY_FILES), $(call word-colon,2,$(cf)))))

$(INSTALLED_RPIBOOTIMAGE_TARGET): $(RPI_BOOT_DISK_TOOLS) $(INSTALLED_FILES_RPIBOOT)
	dd bs=1 seek=$(BOARD_RPIBOOTIMAGE_PARTITION_SIZE) if=/dev/null of=$@;
	$(RPI_BOOT_IMAGE_HOST_FALLOCATE) -d $@
	$(RPI_BOOT_IMAGE_HOST_MKFS_FAT) -n $(TARGET_RPIBOOT_IMAGE_NAME) --mbr=n $@;
	$(RPI_BOOT_IMAGE_HOST_MCOPY) -s -i $@ $(PRODUCT_OUT)/$(TARGET_COPY_OUT_RPIBOOT)/* ::

$(INSTALLED_RPIMISCIMAGE_TARGET): $(RPI_BOOT_DISK_TOOLS) $(INSTALLED_FILES_RPIMISC)
	dd bs=1 seek=$(BOARD_RPIMISCIMAGE_PARTITION_SIZE) if=/dev/null of=$@;
	$(RPI_BOOT_IMAGE_HOST_FALLOCATE) -d $@
	$(RPI_BOOT_IMAGE_HOST_MKFS_FAT) -n $(TARGET_RPIMISC_IMAGE_NAME) --mbr=n $@;
	$(RPI_BOOT_IMAGE_HOST_MCOPY) -s -i $@ $(PRODUCT_OUT)/$(TARGET_COPY_OUT_RPIMISC)/* ::

# Add these custom images to "radio" images i.e. custom firmware that is a part of the OTA etc.
$(call add-radio-file,$(INSTALLED_RPIBOOTIMAGE_TARGET))
$(call add-radio-file,$(INSTALLED_RPIMISCIMAGE_TARGET))

LBA_SIZE := 512

INSTALLED_RPI_PROVISIONING_DISK_IMAGE_TARGET := $(PRODUCT_OUT)/$(TARGET_RPI_PROVISIONING_DISK_IMAGE_NAME).img
.PHONY: rpiprovisionimage
rpiprovisionimage: $(INSTALLED_RPI_PROVISIONING_DISK_IMAGE_TARGET)

$(INSTALLED_RPI_PROVISIONING_DISK_IMAGE_TARGET): $(RPI_BOOT_DISK_TOOLS) $(INSTALLED_RPIBOOTIMAGE_TARGET) $(INSTALLED_RPIMISCIMAGE_TARGET)
# create an image file of required size
	dd bs=1 seek=$(BOARD_RPI_PROVISIONAL_DISK_SIZE) if=/dev/null of=$@;
# make the file sparse to save space
	$(RPI_BOOT_IMAGE_HOST_FALLOCATE) -d $@

# We apply the partitioning files to the disk image but replacing tokens with environment variables we set up
# It has to be a bash one liner otherwise each line executes in a separate shell process
# 	and exported environment variables won't work.
	export rpimisc_size_lba=$$( expr $(BOARD_RPIMISCIMAGE_PARTITION_SIZE) / $(LBA_SIZE) ); \
		export rpiboot_size_lba=$$( expr $(BOARD_RPIBOOTIMAGE_PARTITION_SIZE) / $(LBA_SIZE) ); \
		$(RPI_BOOT_IMAGE_HOST_ENVSUBST) < $(RPI_BOOT_IMAGE_LOCAL_PATH)/partitioning/pt_gpt_provisional.template | $(RPI_BOOT_IMAGE_HOST_SFDISK) $@; \
		$(RPI_BOOT_IMAGE_HOST_ENVSUBST) < $(RPI_BOOT_IMAGE_LOCAL_PATH)/partitioning/pt_mbr.template | $(RPI_BOOT_IMAGE_HOST_SFDISK) --label-nested dos $@

# Now we find the partitions offsets, put them into a bash array and write partition images to the full disk image
	offsets=( $$( $(RPI_BOOT_IMAGE_HOST_SFDISK) --quiet --list -o START $@ | tail -n +2 ) ); \
		dd if=$(INSTALLED_RPIMISCIMAGE_TARGET) of=$@ bs=$(LBA_SIZE) seek=$${offsets[0]} conv=notrunc; \
		dd if=$(INSTALLED_RPIBOOTIMAGE_TARGET) of=$@ bs=$(LBA_SIZE) seek=$${offsets[1]} conv=notrunc; \
		dd if=$(INSTALLED_RPIBOOTIMAGE_TARGET) of=$@ bs=$(LBA_SIZE) seek=$${offsets[2]} conv=notrunc;
