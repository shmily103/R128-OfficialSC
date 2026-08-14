#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

git clone https://github.com/shmily103/R128-OfficialSC.git
cp -r R128-OfficialSC/path/01_leds target/linux/mediatek/filogic/base-files/etc/board.d
cp -r R128-OfficialSC/path/02_network target/linux/mediatek/filogic/base-files/etc/board.d
cp -r R128-OfficialSC/path/mediatek_filogic package/boot/uboot-tools/uboot-envtools/files
cp -r R128-OfficialSC/path/mt7981b-Zhao-7981R128-mtkuboot.dts target/linux/mediatek/dts
cp -r R128-OfficialSC/path/filogic.mk target/linux/mediatek/image
cp -r R128-OfficialSC/path/platform.sh target/linux/mediatek/filogic/base-files/lib/upgrade
rm -rf R128-OfficialSC
