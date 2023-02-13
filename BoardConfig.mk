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

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_VARIANT := cortex-a72
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=


BOARD_RPI_FULL_DISK_SIZE := 31914983424 # 32GB
BOARD_RPI_PROVISIONAL_DISK_SIZE := 536870912 # 512MB
BOARD_RPIBOOTIMAGE_PARTITION_SIZE := 134217728 # 128MB
BOARD_RPIMISCIMAGE_PARTITION_SIZE := 33554432 # 32MB
