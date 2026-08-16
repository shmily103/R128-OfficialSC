#!/usr/bin/env bash
set -e

OW_VER="25.12.5"

[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

TARGET=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

# 直接从 kmods 目录名提取 vermagic (匹配末尾 32 位 MD5 哈希)
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
VERMAGIC=$(curl -sL --connect-timeout 10 "$URL" | grep -oE '[a-f0-9]{32}' | head -n 1)

[ -n "$VERMAGIC" ] || { echo "Error: Failed to fetch vermagic!"; exit 1; }

sed -i "s|grep '=\[ym\]'.*mkhash md5 > \$(LINUX_DIR)/\.vermagic|echo \"${VERMAGIC}\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk

echo "Successfully injected vermagic: ${VERMAGIC}"
