#!/usr/bin/env bash
set -e

# 自动处理分支名：如果是 v25.12.5，剔除 v 提取为 25.12.5
OW_VER="${BRANCH_NAME#v}"

[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

# 获取目标架构
TARGET=$(make --no-print-directory val.BOARD 2>/dev/null || grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(make --no-print-directory val.SUBTARGET 2>/dev/null || grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

# 获取官方 kmods 目录中的 vermagic 指纹
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
VERMAGIC=$(curl -sL --connect-timeout 15 "$URL" | grep -oE '[a-f0-9]{32}' | head -n 1)

[ -n "$VERMAGIC" ] || { echo "Error: Failed to fetch vermagic!"; exit 1; }

# 修改 Makefile 指纹规则（修正正则匹配并保留 Makefile 规则首行的 Tab 制表符 \t）
sed -i "s|grep '=[ym]'.*|\techo \"${VERMAGIC}\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk

# 双重保险：避免部分分支版本在配置覆盖时重置 vermagic
echo "CONFIG_VERMAGIC=\"${VERMAGIC}\"" >> .config

echo "==> Successfully injected vermagic: ${VERMAGIC}"
