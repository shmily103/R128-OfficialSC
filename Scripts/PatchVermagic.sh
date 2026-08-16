#!/usr/bin/env bash
set -e

OW_VER="25.12.5"

[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

# 1. 解析架构并打印
TARGET=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

echo "==> Target: ${TARGET}/${SUBTARGET}"

# 2. 拼接 URL 并抓取 HTML
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
echo "==> Fetching: ${URL}"

HTML=$(curl -sL --connect-timeout 15 "$URL")

# 3. 检查是否返回 404
if echo "$HTML" | grep -qI "404 Not Found"; then
    echo "Error: 官方下载站不存在此路径 (404 Not Found)！请检查 OW_VER (${OW_VER}) 或 Target 是否匹配。"
    exit 1
fi

# 4. 精准匹配 32 位 MD5 哈希
VERMAGIC=$(echo "$HTML" | grep -oE '[a-f0-9]{32}' | head -n 1)

if [ -z "$VERMAGIC" ]; then
    echo "Error: 提取 vermagic 失败！"
    echo "--- 官方返回的 HTML 前 20 行内容如下 ---"
    echo "$HTML" | head -n 20
    echo "--------------------------------------"
    exit 1
fi

# 5. 替换 Makefile 中的指纹逻辑
sed -i "s|grep '=\[ym\]'.*mkhash md5 > \$(LINUX_DIR)/\.vermagic|echo \"${VERMAGIC}\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk

echo "==> Successfully injected vermagic: ${VERMAGIC}"
