#!/bin/bash
set -e

# 自动处理分支名：如果是 v25.12.5，剔除 v 提取为 25.12.5
OW_VER="${BRANCH_NAME#v}"

[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

# 获取目标架构
TARGET=$(make --no-print-directory val.BOARD 2>/dev/null || grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(make --no-print-directory val.SUBTARGET 2>/dev/null || grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

# =========================================================
# 1. 保留你原有的获取官方指纹逻辑
# =========================================================
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
VERMAGIC=$(curl -sL --connect-timeout 15 "$URL" | grep -oE '[a-f0-9]{32}' | head -n 1)

if [ -z "$VERMAGIC" ]; then
    echo "[-] Error: Failed to fetch VERMAGIC from $URL"
    exit 1
fi

echo "[+] Successfully fetched Official Vermagic: $VERMAGIC"

# =========================================================
# 2. 劫持 scripts/ext-vermagic (去除文件存在性检查，强行创建/覆盖)
# =========================================================
mkdir -p scripts
cat << 'EOF' > scripts/ext-vermagic
#!/bin/sh
EOF
echo "echo \"$VERMAGIC\"" >> scripts/ext-vermagic
chmod +x scripts/ext-vermagic
echo "[+] Successfully hijacked scripts/ext-vermagic"

# =========================================================
# 3. 修改 include 编译规则 (双重保险)
# =========================================================
if [ -f "include/kernel-defaults.mk" ]; then
    sed -i "s|\$(TOPDIR)/scripts/ext-vermagic.*|echo \"$VERMAGIC\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk
    echo "[+] Patched include/kernel-defaults.mk"
fi

if [ -f "include/kernel-build.mk" ]; then
    sed -i "s|cat \$(LINUX_DIR)/\.vermagic.*|echo \"$VERMAGIC\"|g" include/kernel-build.mk
    echo "[+] Patched include/kernel-build.mk"
fi

# =========================================================
# 4. 写入根目录 .vermagic
# =========================================================
echo "$VERMAGIC" > .vermagic
echo "[+] Injected vermagic into root .vermagic file."
