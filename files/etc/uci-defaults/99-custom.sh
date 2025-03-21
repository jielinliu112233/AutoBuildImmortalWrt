#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE

# 设置默认防火墙规则，方便首次访问 WebUI
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

# 检查配置文件 pppoe-settings 是否存在
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
else
   # 读取 pppoe 配置（但后续不再使用，因为无 WAN 口）
   . "$SETTINGS_FILE"
fi

# 计算网卡数量
count=0
ifnames=""
for iface in /sys/class/net/*; do
  iface_name=$(basename "$iface")
  # 检查是否为物理网卡（排除回环设备和无线设备）
  if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
    count=$((count + 1))
    ifnames="$ifnames $iface_name"
  fi
done
# 删除多余空格
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')

# 网络设置：所有网口均作为 LAN 口
# --------------------------------
# 设置 LAN 口为静态 IP
uci set network.lan.proto='static'
uci set network.lan.ipaddr='10.0.0.104'  # 静态 IP
uci set network.lan.netmask='255.255.255.0'
uci set network.lan.gateway='10.0.0.100'
uci set network.lan.dns='10.0.0.100'

# 关闭 DHCP 服务
uci set dhcp.lan.ignore='1'

# 将所有物理网口绑定到 LAN 桥接
section=$(uci show network | awk -F '[.=]' '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')
if [ -z "$section" ]; then
   echo "error：cannot find device 'br-lan'." >> $LOGFILE
else
   # 删除原来的 ports 列表
   uci -q delete "network.$section.ports"
   # 添加所有网口到 LAN 桥接
   for port in $ifnames; do
      uci add_list "network.$section.ports"="$port"
   done
   echo "All ports added to LAN bridge." >> $LOGFILE
fi

# 删除 WAN 和 WAN6 接口（如果存在）
uci -q delete network.wan
uci -q delete network.wan6

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''
uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by wukongdaily"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
