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

# =========================================================
# 6. 解决 base-files 版本问题：直接解析官方 apk 包文件名
# =========================================================
APK_URL="https://downloads.openwrt.org/releases/${OW_VER}/targets/${TARGET}/${SUBTARGET}/packages/"
echo "[+] Fetching base-files version from: $APK_URL"

# 从网页HTML列表中匹配 base-files-xxxx~xxxxxx.apk 中的版本号 (例如 1711~f5dae5ece4)
BASE_FILES_VER=$(curl -sL --connect-timeout 15 "$APK_URL" | grep -oE 'base-files-[0-9]+~[a-f0-9]+\.apk' | head -n 1 | sed -E 's/base-files-(.*)\.apk/\1/')

if [ -n "$BASE_FILES_VER" ]; then
    echo "[+] Successfully fetched Official base-files Version: $BASE_FILES_VER"
    
    # 拆分波浪号前面的 PKG_RELEASE (1711) 和后面的 Commit Hash (f5dae5ece4)
    PKG_REL=$(echo "$BASE_FILES_VER" | cut -d'~' -f1)
    PKG_HASH=$(echo "$BASE_FILES_VER" | cut -d'~' -f2)

    # 1. 替换 package/base-files/Makefile 里的 PKG_RELEASE 为 1711
    if [ -n "$PKG_REL" ] && [ -f "package/base-files/Makefile" ]; then
        sed -i "s/PKG_RELEASE:=.*/PKG_RELEASE:=$PKG_REL/g" package/base-files/Makefile
        echo "[+] Successfully patched package/base-files/Makefile PKG_RELEASE to $PKG_REL"
    fi

    # 2. 劫持 scripts/getver.sh 输出波浪号后面的 Hash (f5dae5ece4)
    if [ -n "$PKG_HASH" ]; then
        cat << EOF > scripts/getver.sh
#!/bin/sh
echo "r0-$PKG_HASH"
EOF
        chmod +x scripts/getver.sh
        echo "[+] Successfully hijacked scripts/getver.sh with Hash: $PKG_HASH"
    fi
else
    echo "[-] Warning: Failed to fetch base-files version from $APK_URL"
fi
