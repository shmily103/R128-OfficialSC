#!/usr/bin/env bash
set -e

OW_VER="25.12.5"

[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

TARGET=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

# 1. 动态获取 kmods 目录下的内核版本（例: 6.6.x-x-xxx）
BASE_URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods"
KMOD_VER=$(curl -sL --connect-timeout 10 "$BASE_URL/" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-[a-f0-9]+' | head -n 1)

# 2. 拼接完整的 Packages.manifest 地址
URL="${BASE_URL}/${KMOD_VER}/Packages.manifest"

VERMAGIC=$(curl -sL --connect-timeout 10 "$URL" | grep -A 8 "^Package: kernel$" | grep "^Version:" | awk -F'-' '{print $NF}')

[ -n "$VERMAGIC" ] || { echo "Error: Failed to fetch vermagic!"; exit 1; }

sed -i "s|grep '=\[ym\]'.*mkhash md5 > \$(LINUX_DIR)/\.vermagic|echo \"${VERMAGIC}\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk

echo "Successfully injected vermagic: ${VERMAGIC}"
