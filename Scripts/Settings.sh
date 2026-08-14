#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

# 修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
# 修改 lan 关联 IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
# 添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

# 修改默认 Wi-Fi 配置
WIFI_FILE="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"

if [ -f "$WIFI_FILE" ]; then
    # 1. 替换加密方式、密码和开启状态
    sed -i "s|set \${si}\.encryption='.*'|set \${si}\.encryption='sae-mixed'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.key='.*'|set \${si}\.key='$WRT_WORD'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.disabled='.*'|set \${si}\.disabled='0'|g" "$WIFI_FILE"

    # 2. 修改 SSID
    sed -i "s|set \${si}\.ssid='.*'|set \${si}\.ssid='\${band_name == \"2g\" ? \"$WRT_SSID\" : \"$WRT_SSID-5G\"}'|g" "$WIFI_FILE"

    echo "Wi-Fi 默认配置修改成功（已区分 2.4G 与 5G）！"
else
    echo "错误：未找到目标文件 $WIFI_FILE"
fi

# 修改系统默认配置 (IP、主机名、香港时区)
CFG_FILE="./package/base-files/files/bin/config_generate"
if [ -f "$CFG_FILE" ]; then
    # 1. 修改默认 IP 地址
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$CFG_FILE"

    # 2. 修改默认主机名
    sed -i "s/set system\.@system\[-1\]\.hostname='.*'/set system.@system[-1].hostname='$WRT_NAME'/g" "$CFG_FILE"

    # 3. 修改默认时区 (分别替换 timezone 和 zonename)
    sed -i "s/set system\.@system\[-1\]\.timezone='.*'/set system.@system[-1].timezone='HKT-8'/g" "$CFG_FILE"
    sed -i "s/set system\.@system\[-1\]\.zonename='.*'/set system.@system[-1].zonename='Asia\/Hong_Kong'/g" "$CFG_FILE"

    echo "系统默认参数 (IP/主机名/香港时区) 修改成功！"
else
    echo "错误：未找到目标文件 $CFG_FILE"
fi

# 配置文件追加
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 修复fstab报错
mkdir -p package/base-files/files/etc/config && cat << 'EOF' > package/base-files/files/etc/config/fstab
config global
	option anon_swap '0'
	option anon_mount '1'
	option auto_swap '1'
	option auto_mount '1'
	option delay_root '5'
	option check_fs '0'
EOF

# 手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# 无 WIFI 配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi
