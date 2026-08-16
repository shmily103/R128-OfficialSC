#!/usr/bin/env bash
set -e

# 设置 OpenWrt 目标版本
OW_VER="25.12.5"

# 1. 检查是否存在 .config 文件
if [ ! -f ".config" ]; then
    echo "错误：未找到 .config 文件，请先生成编译配置！"
    exit 1
fi

# 2. 自动从 .config 解析目标主/子架构
TARGET=$(grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

if [ -z "$TARGET" ] || [ -z "$SUBTARGET" ]; then
    echo "错误：无法从 .config 文件解析 TARGET 或 SUBTARGET！"
    exit 1
fi

echo "目标架构: ${TARGET}/${SUBTARGET}"

# 3. 抓取官方 Packages.manifest 提取 vermagic 指纹
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/packages/Packages.manifest"
echo "正在拉取指纹: ${URL}"

VERMAGIC=$(curl -sL --connect-timeout 10 "$URL" | grep -A 8 "^Package: kernel$" | grep "^Version:" | awk -F'-' '{print $NF}')

# 如果官方源超时，自动使用清华镜像源重试
if [ -z "$VERMAGIC" ]; then
    echo "官方节点响应超时，尝试从清华镜像源拉取..."
    URL="https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/packages/Packages.manifest"
    VERMAGIC=$(curl -sL --connect-timeout 10 "$URL" | grep -A 8 "^Package: kernel$" | grep "^Version:" | awk -F'-' '{print $NF}')
fi

if [ -z "$VERMAGIC" ]; then
    echo "错误：获取 vermagic 失败，请检查网络或版本号设置！"
    exit 1
fi

echo "成功获取官方 vermagic: ${VERMAGIC}"

# 4. 替换 include/kernel-defaults.mk 中的指纹生成规则
MK_FILE="include/kernel-defaults.mk"

if [ ! -f "$MK_FILE" ]; then
    echo "错误：未找到 $MK_FILE 文件，请确认在 OpenWrt 源码根目录下运行！"
    exit 1
fi

sed -i "s|grep '=\[ym\]'.*mkhash md5 > \$(LINUX_DIR)/\.vermagic|echo \"${VERMAGIC}\" > \$(LINUX_DIR)/\.vermagic|g" "$MK_FILE"

echo "内核指纹已成功注入至 ${MK_FILE}"
