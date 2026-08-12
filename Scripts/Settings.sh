#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#修改默认主题
sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" $(find ./feeds/luci/collections/ -type f -name "Makefile")
#修改lan关联IP
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $(find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js")
#添加编译日期标识
sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_MARK-$WRT_DATE')/g" $(find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js")

WIFI_FILE="package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
if [ -f "$WIFI_FILE" ]; then
    sed -i "s|set \${si}\.ssid='.*'|set \${si}\.ssid='$WRT_SSID'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.encryption='.*'|set \${si}\.encryption='sae-mixed'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.key='.*'|set \${si}\.key='$WRT_WORD'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.disabled='.*'|set \${si}\.disabled='0'|g" "$WIFI_FILE"
    echo "Wi-Fi 默认配置修改成功！"
else
    echo "错误：未找到目标文件 $WIFI_FILE"
fi

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE
if [ -f "$CFG_FILE" ]; then
    # 修改默认时区和时区显示名称
    sed -i "s|set system.@system\[0\].timezone='.*'|set system.@system[0].timezone='HKT-8'|g" "$CFG_FILE"
    sed -i "s|set system.@system\[0\].zonename='.*'|set system.@system[0].zonename='Asia/Hong_Kong'|g" "$CFG_FILE"
    echo "默认时区修改为 Asia/Hong_Kong 成功！"
fi

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#无WIFI配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi
