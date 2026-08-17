#!/bin/bash
set -e

OW_VER="${BRANCH_NAME#v}"
[ -f ".config" ] || { echo "Error: .config not found!"; exit 1; }

TARGET=$(make --no-print-directory val.BOARD 2>/dev/null || grep "^CONFIG_TARGET_BOARD=" .config | cut -d'=' -f2 | tr -d '"')
SUBTARGET=$(make --no-print-directory val.SUBTARGET 2>/dev/null || grep "^CONFIG_TARGET_SUBTARGET=" .config | cut -d'=' -f2 | tr -d '"')

# 1. 获取官方指纹
URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/kmods/"
VERMAGIC=$(curl -sL --connect-timeout 15 "$URL" | grep -oE '[a-f0-9]{32}' | head -n 1)

if [ -z "$VERMAGIC" ]; then
    echo "[-] Error: Failed to fetch VERMAGIC from $URL"
    exit 1
fi

echo "[+] Successfully fetched Official Vermagic: $VERMAGIC"

# 2. 劫持 ext-vermagic 脚本
mkdir -p scripts
cat << EOF > scripts/ext-vermagic
#!/bin/sh
echo "$VERMAGIC"
EOF
chmod +x scripts/ext-vermagic

# 3. 强行修改 include/kernel-version.mk 中的 LINUX_VERMAGIC 变量定义（最关键的一步！）
# 无论 Makefile 原本怎么用 $(shell ...) 计算，直接强制赋值为官方指纹
if [ -f "include/kernel-version.mk" ]; then
    echo "LINUX_VERMAGIC:=$VERMAGIC" >> include/kernel-version.mk
    echo "[+] Overridden LINUX_VERMAGIC in include/kernel-version.mk"
fi

if [ -f "include/kernel.mk" ]; then
    echo "LINUX_VERMAGIC:=$VERMAGIC" >> include/kernel.mk
    echo "[+] Overridden LINUX_VERMAGIC in include/kernel.mk"
fi

# 4. 强制替换 package/kernel/linux/Makefile 中可能的写死逻辑
find include/ package/kernel/ -type f \( -name "*.mk" -o -name "Makefile" \) -exec sed -i "s/\$(LINUX_VERMAGIC)/$VERMAGIC/g" {} + 2>/dev/null || true
echo "[+] Replaced all \$(LINUX_VERMAGIC) references with $VERMAGIC"

# 5. 写入各级 .vermagic 标记文件
echo "$VERMAGIC" > .vermagic
find build_dir/ -name ".vermagic" -exec sh -c 'echo "$1" > "$2"' _ "$VERMAGIC" {} \; 2>/dev/null || true

echo "[+] Complete injection executed successfully."

# 6. 解决 base-files 版本问题：抓取官方 version.buildinfo 并劫持版本号
VERSION_URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/version.buildinfo"
OFFICIAL_REV=$(curl -sL --connect-timeout 15 "$VERSION_URL" | tr -d '\r\n')

if [ -n "$OFFICIAL_REV" ]; then
    echo "[+] Successfully fetched Official Revision: $OFFICIAL_REV"
    
    # 劫持 getver.sh
    cat << EOF > scripts/getver.sh
#!/bin/sh
echo "$OFFICIAL_REV"
EOF
    chmod +x scripts/getver.sh

    # 提取 Revision 中的数字部分 (比如从 r1711-f5dae5ece4 提取出 1711)
    # 强行修改 package/base-files/Makefile 里的 PKG_RELEASE，把默认的 1 改成官方数字
    REV_NUM=$(echo "$OFFICIAL_REV" | grep -oE '[0-9]+' | head -n 1)
    if [ -n "$REV_NUM" ] && [ -f "package/base-files/Makefile" ]; then
        sed -i "s/PKG_RELEASE:=.*/PKG_RELEASE:=$REV_NUM/g" package/base-files/Makefile
        echo "[+] Successfully patched package/base-files/Makefile PKG_RELEASE to $REV_NUM"
    fi
fi
