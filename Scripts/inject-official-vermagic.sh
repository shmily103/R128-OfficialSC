#!/bin/bash

# =========================================================
# 1. 获取官方 vermagic (保留你原有的获取逻辑)
# =========================================================
# 假设你脚本前面获取到的指纹变量是 TARGET_VERMAGIC
# TARGET_VERMAGIC=$(curl -s .....)

if [ -z "$TARGET_VERMAGIC" ]; then
    echo "[-] Error: TARGET_VERMAGIC is empty!"
    exit 1
fi

echo "[+] Target Official Vermagic: $TARGET_VERMAGIC"

# =========================================================
# 2. 核心拦截：直接替换 scripts/ext-vermagic 脚本本身
# 彻底破除编译过程中“内核重新计算并覆盖 vermagic”的时序问题
# =========================================================
if [ -f "scripts/ext-vermagic" ]; then
    cat << EOF > scripts/ext-vermagic
#!/bin/sh
echo "$TARGET_VERMAGIC"
EOF
    chmod +x scripts/ext-vermagic
    echo "[+] Successfully hijacked scripts/ext-vermagic"
fi

# =========================================================
# 3. 强行修改 include/kernel-defaults.mk 规则 (双重保险)
# 防止 Makefile 使用其他方式跳过 ext-vermagic 计算
# =========================================================
if [ -f "include/kernel-defaults.mk" ]; then
    # 替换所有向 .vermagic 写入的命令，直接写死目标值
    sed -i "s|\$(TOPDIR)/scripts/ext-vermagic.*|echo \"$TARGET_VERMAGIC\" > \$(LINUX_DIR)/.vermagic|g" include/kernel-defaults.mk
    echo "[+] Patched include/kernel-defaults.mk"
fi

if [ -f "include/kernel-build.mk" ]; then
    sed -i "s|cat \$(LINUX_DIR)/\.vermagic.*|echo \"$TARGET_VERMAGIC\"|g" include/kernel-build.mk
    echo "[+] Patched include/kernel-build.mk"
fi

# =========================================================
# 4. 预先写入当前根目录的 .vermagic
# =========================================================
echo "$TARGET_VERMAGIC" > .vermagic
echo "[+] Injected vermagic into root .vermagic file."
