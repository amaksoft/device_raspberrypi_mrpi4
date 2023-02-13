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


###
# Input variables:
# TARGET_U_BOOT_SOURCE: the path to u-boot source code
# TARGET_U_BOOT_CONFIG: the path to u-boot config file
# TARGET_U_BOOT_SCRIPT: the path to u-boot boot script file
# TARGET_U_BOOT_ENV: the path to u-boot environment file
# TARGET_U_BOOT_IMAGE: which u-boot image to build
# TARGET_U_BOOT_SCRIPT_IMAGE: u-boot boot script image to create
# TARGET_U_BOOT_ENV_IMAGE: u-boot environment image to create
# TARGET_U_BOOT_CPU_ARCH: CPU architecture to build u-boot for
# TARGET_U_BOOT_CROSS_COMPILE: Cross compile triplet to use for building u-boot
#
# Output variables:
# U-BOOT_INTM_IMG: full path to generated u-boot image in intermediates
# U-BOOT_INTM_SCRIPT_IMG: full path to generated boot script image in intermediates
# U-BOOT_INTM_ENV_IMG: full path to generated environment image in intermediates
###

# Required directories for toolchains
U-BOOT_CLANG_TOOLCHAIN_DIR := $(PWD)/prebuilts/clang/host/$(HOST_PREBUILT_TAG)/clang-r450784d
U-BOOT_GCC_TOOLCHAIN_DIR := $(PWD)/prebuilts/gcc/$(HOST_PREBUILT_TAG)/$(TARGET_U_BOOT_CPU_ARCH)/$(TARGET_U_BOOT_CROSS_COMPILE)-4.9
U-BOOT_BUILD_TOOLS_DIR := $(PWD)/prebuilts/build-tools/$(HOST_PREBUILT_TAG)

# Paths for the tools to be used
U-BOOT_TOOLCHAIN_PATH := $(U-BOOT_CLANG_TOOLCHAIN_DIR)/bin
U-BOOT_BUILD_TOOLS_PATH := $(U-BOOT_BUILD_TOOLS_DIR)/bin
U-BOOT_MAKE := $(U-BOOT_BUILD_TOOLS_PATH)/make

# Overide the compilers and binutils
U-BOOT_MAKE_OPTS += AS=$(U-BOOT_TOOLCHAIN_PATH)/llvm-as
U-BOOT_MAKE_OPTS += CC='$(U-BOOT_TOOLCHAIN_PATH)/clang -target $(TARGET_U_BOOT_CROSS_COMPILE)'
U-BOOT_MAKE_OPTS += HOSTCC=$(U-BOOT_TOOLCHAIN_PATH)/clang
U-BOOT_MAKE_OPTS += LD=$(U-BOOT_TOOLCHAIN_PATH)/ld.lld
U-BOOT_MAKE_OPTS += AR=$(U-BOOT_TOOLCHAIN_PATH)/llvm-ar
U-BOOT_MAKE_OPTS += NM=$(U-BOOT_TOOLCHAIN_PATH)/llvm-nm
U-BOOT_MAKE_OPTS += OBJDUMP=$(U-BOOT_TOOLCHAIN_PATH)/llvm-objdump
U-BOOT_MAKE_OPTS += READELF=$(U-BOOT_TOOLCHAIN_PATH)/llvm-readelf
U-BOOT_MAKE_OPTS += OBJSIZE=$(U-BOOT_TOOLCHAIN_PATH)/llvm-size
U-BOOT_MAKE_OPTS += STRIP=$(U-BOOT_TOOLCHAIN_PATH)/llvm-strip
# Add linker flags for clang to use lld linker
U-BOOT_MAKE_OPTS += LDFLAGS=-fuse-ld=lld
U-BOOT_MAKE_OPTS += HOSTLDFLAGS=-fuse-ld=lld

# U-boot needs libgcc, clang doesn't have it. We will have to borrow it from gcc toolchain
U-BOOT_MAKE_OPTS += PLATFORM_LIBGCC=$(U-BOOT_GCC_TOOLCHAIN_DIR)/lib/gcc/$(TARGET_U_BOOT_CROSS_COMPILE)/4.9.x/libgcc.a

# U-boot successfully builds and links with clang + llvm utils, except for final stage: copying objects into images
U-BOOT_MAKE_OPTS_FULL_LLVM := $(U-BOOT_MAKE_OPTS)
U-BOOT_MAKE_OPTS_FULL_LLVM += OBJCOPY=$(U-BOOT_TOOLCHAIN_PATH)/llvm-objcopy

# Images require finctionality that llvm-objcopy doesn't have yet. Defer to gnu objcopy
U-BOOT_MAKE_OPTS_LLVM_GNU_OBJCOPY := $(U-BOOT_MAKE_OPTS)
U-BOOT_MAKE_OPTS_LLVM_GNU_OBJCOPY += OBJCOPY=$(U-BOOT_GCC_TOOLCHAIN_DIR)/bin/$(TARGET_U_BOOT_CROSS_COMPILE)-objcopy

# Build target paths
U-BOOT_INTM := $(OUT_DIR)/target/product/$(PRODUCT_DEVICE)/obj/U-BOOT_OBJ
U-BOOT_CONFIG := $(U-BOOT_INTM)/.config
U-BOOT_INTM_BINARY := $(U-BOOT_INTM)/u-boot

# The resulting artifacts
U-BOOT_INTM_IMG := $(U-BOOT_INTM)/$(TARGET_U_BOOT_IMAGE)
U-BOOT_INTM_SCRIPT_IMG := $(U-BOOT_INTM)/$(TARGET_U_BOOT_SCRIPT_IMAGE)
U-BOOT_INTM_ENV_IMG := $(U-BOOT_INTM)/$(TARGET_U_BOOT_ENV_IMAGE)

# create phony targets to build standalone uboot with `make u-boot u-boot-scr-uimg uboot-env-bin`
.PHONY: u-boot u-boot-scr-uimg uboot-env-bin
u-boot: $(U-BOOT_INTM_IMG)
u-boot-scr-uimg: $(U-BOOT_INTM_SCRIPT_IMG)
uboot-env-bin: $(U-BOOT_INTM_ENV_IMG)

# Create our output directory
$(U-BOOT_INTM):
	mkdir -p $(U-BOOT_INTM)

# Create .config file
$(U-BOOT_CONFIG): $(U-BOOT_INTM)
	@if [ -f $(TARGET_U_BOOT_CONFIG) ]; then \
	    echo "Using supplied config $(TARGET_U_BOOT_CONFIG)"; \
		cp -f $(TARGET_U_BOOT_CONFIG) $@; \
	else \
	    echo "Using $(TARGET_U_BOOT_CONFIG) as defconfig target"; \
		PATH=$(U-BOOT_TOOLCHAIN_PATH)/bin:$(U-BOOT_BUILD_TOOLS_DIR)/bin/:$$PATH $(U-BOOT_MAKE) -C $(TARGET_U_BOOT_SOURCE) \
			$(U-BOOT_CROSS_COMPILE_OPTS) $(U-BOOT_MAKE_OPTS_FULL_LLVM) O=$(abspath $(U-BOOT_INTM)) $(TARGET_U_BOOT_CONFIG); \
	fi

# Buiild generic u-boot binary with clang + llvm toolchain
$(U-BOOT_INTM_BINARY): $(U-BOOT_CONFIG)
	PATH=$(U-BOOT_BUILD_TOOLS_PATH):$$PATH $(U-BOOT_MAKE) -C $(TARGET_U_BOOT_SOURCE) $(U-BOOT_CROSS_COMPILE_OPTS) \
		$(U-BOOT_MAKE_OPTS_FULL_LLVM) O=$(abspath $(U-BOOT_INTM)) u-boot

# Use gnu objcopy to create the images
$(U-BOOT_INTM_IMG): $(U-BOOT_INTM_BINARY)
	PATH=$(U-BOOT_BUILD_TOOLS_PATH):$$PATH $(U-BOOT_MAKE) -C $(TARGET_U_BOOT_SOURCE) $(U-BOOT_CROSS_COMPILE_OPTS) \
		$(U-BOOT_MAKE_OPTS_LLVM_GNU_OBJCOPY) O=$(abspath $(U-BOOT_INTM)) $(TARGET_U_BOOT_IMAGE)

$(U-BOOT_INTM_SCRIPT_IMG): $(U-BOOT_INTM_BINARY) # the tools are built along with the main binary
	$(U-BOOT_INTM)/tools/mkimage -A $(TARGET_ARCH) -T script -C none -n "Boot script" -d $(TARGET_U_BOOT_SCRIPT) $(U-BOOT_INTM_SCRIPT_IMG)

$(U-BOOT_INTM_ENV_IMG): $(U-BOOT_INTM_BINARY) # the tools are built along with the main binary
	$(U-BOOT_INTM)/tools/mkenvimage -s 4096 -o $(U-BOOT_INTM_ENV_IMG) $(TARGET_U_BOOT_ENV)
