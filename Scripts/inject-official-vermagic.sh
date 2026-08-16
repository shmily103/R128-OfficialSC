#!/bin/bash

# =========================================================
# 1. 保留你原有的获取官方指纹逻辑（未做任何修改）
# =========================================================
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
VERMAGIC=$(curl -sL --connect-timeout 15 "$URL" | grep -oE '[a-f0-9]{32}' | head -n 1)

if [ -z "$VERMAGIC" ]; then
    echo "[-] Error: Failed to fetch VERMAGIC from $URL"
    exit 1
fi

echo "[+] Successfully fetched Official Vermagic: $VERMAGIC"

# =========================================================
# 2. 劫持 scripts/ext-vermagic (彻底解决内核编译重新计算并覆盖的问题)
# =========================================================
if [ -f "scripts/ext-vermagic" ]; then
    cat << EOF > scripts/ext-vermagic
#!/bin/sh
echo "$VERMAGIC"
EOF
    chmod +x scripts/ext-vermagic
    echo "[+] Successfully hijacked scripts/ext-vermagic"
fi

# =========================================================
# 3. 修改 include 编译规则 (双重保险)
# =========================================================
if [ -f "include/kernel-defaults.mk" ]; then
    sed -i "s|\$(TOPDIR)/scripts/ext-vermagic.*|echo \"$VERMAGIC\" > \$(LINUX_DIR)/\.vermagic|g" include/kernel-defaults.mk
    echo "[+] Patched include/kernel-defaults.mk"
fi

if [ -f "include/kernel-build.mk" ]; me
if [ -f "include/kernel-build.mk" ]; then
    sed -i "s|cat \$(LINUX_DIR)/\.vermagic.*|echo \"$VERMAGIC\"|g" include/kernel-build.mk
    echo "[+] Patched include/kernel-build.mk"
fi

# =========================================================
# 4. 写入根目录 .vermagic
# =========================================================
echo "$VERMAGIC" > .vermagic
echo "[+] Injected vermagic into root .vermagic file."
