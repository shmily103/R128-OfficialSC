# 赵老板设备R128，适配官方源码仓v25.12版本，云编译项目。
完全零添加，只有硬件相关的驱动。
在Config/R128-OfficialSC.txt文件中增减定制插件。

在.github/workflows/R128-OfficialSC.yml文件中修改默认的参数配置：
<br>  WRT_THEME: # 默认 LucI 主题
<br>  WRT_NAME:  # 主机名
<br>  WRT_SSID:  # 默认 Wi-Fi 名称
<br>  WRT_WORD:  # 默认 Wi-Fi 密码
<br>  WRT_IP:    # 默认后台登录 IP


补丁的方法增加设备支持：
curl -sSL https://raw.githubusercontent.com/shmily103/R128-OfficialSC/refs/heads/main/add-zhao-7981r128-support.patch | git apply
