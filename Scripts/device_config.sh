#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

git clone https://github.com/shmily103/R128-OfficialSC.git
mkdir package/Panzy && cd package/Panzy
git clone --filter=blob:none --sparse --branch master https://github.com/vernesong/OpenClash.git luci-app-openclash && cd luci-app-openclash && git sparse-checkout set luci-app-openclash && cd ..
git clone --filter=blob:none --sparse --branch master https://github.com/lisaac/luci-app-diskman.git luci-app-diskman && cd luci-app-diskman && git sparse-checkout set applications/luci-app-diskman && cd ..
cd .. && cd ..
cp -r R128-OfficialSC/path/01_leds target/linux/mediatek/filogic/base-files/etc/board.d
cp -r R128-OfficialSC/path/02_network target/linux/mediatek/filogic/base-files/etc/board.d
cp -r R128-OfficialSC/path/mediatek_filogic package/boot/uboot-tools/uboot-envtools/files
cp -r R128-OfficialSC/path/mt7981b-Zhao-7981R128-mtkuboot.dts target/linux/mediatek/dts
cp -r R128-OfficialSC/path/filogic.mk target/linux/mediatek/image
cp -r R128-OfficialSC/path/platform.sh target/linux/mediatek/filogic/base-files/lib/upgrade
cp -r R128-OfficialSC/path/90-default-settings target/linux/mediatek/filogic/base-files/etc/uci-defaults
rm -rf R128-OfficialSC
