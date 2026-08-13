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
    # 替换加密方式、密码和开启状态
    sed -i "s|set \${si}\.encryption='.*'|set \${si}\.encryption='sae-mixed'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.key='.*'|set \${si}\.key='$WRT_WORD'|g" "$WIFI_FILE"
    sed -i "s|set \${si}\.disabled='.*'|set \${si}\.disabled='0'|g" "$WIFI_FILE"

    # 使用 awk 判断频段：按设备 (wifi-device) 块独立判断
    awk -v ssid="$WRT_SSID" '
    /set \${s}=wifi-device/ { 
        # 遇到新设备块时重置标记
        is_5g = 0 
    }
    /set \${s}\.band=/ { 
        # 直接匹配 uc 脚本输出的 band 属性
        if ($0 ~ /5g|6g/) is_5g = 1 
    }
    /set \${si}\.ssid=/ {
        if (is_5g) {
            print "			set ${si}.ssid=\x27" ssid "-5G\x27"
        } else {
            print "			set ${si}.ssid=\x27" ssid "\x27"
        }
        next
    }
    { print }
    ' "$WIFI_FILE" > "${WIFI_FILE}.tmp" && mv "${WIFI_FILE}.tmp" "$WIFI_FILE"

    echo "Wi-Fi 默认配置修改成功（已区分 2.4G 与 5G）！"
else
    echo "错误：未找到目标文件 $WIFI_FILE"
fi

# 修改系统默认配置 (IP、主机名、香港时区)
CFG_FILE="./package/base-files/files/bin/config_generate"
if [ -f "$CFG_FILE" ]; then
    # 修改默认 IP 地址
    sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" "$CFG_FILE"
    # 修改默认主机名
    sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" "$CFG_FILE"
    # 修改默认时区和时区显示名称 (香港 UTC+8)
    sed -i "s|set system.@system\[0\].timezone='.*'|set system.@system[0].timezone='HKT-8'|g" "$CFG_FILE"
    sed -i "s|set system.@system\[0\].zonename='.*'|set system.@system[0].zonename='Asia/Hong_Kong'|g" "$CFG_FILE"
    echo "系统默认参数 (IP/主机名/香港时区) 修改成功！"
else
    echo "错误：未找到目标文件 $CFG_FILE"
fi

# 配置文件追加
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

# 手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

# 无 WIFI 配置标志
if [[ "${WRT_CONFIG,,}" == *"wifi"* && "${WRT_CONFIG,,}" == *"no"* ]]; then
	echo "WRT_WIFI=wifi-no" >> $GITHUB_ENV
fi
