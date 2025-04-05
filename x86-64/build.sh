#!/bin/bash
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings
# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."



# 全插件列表（按功能精准分类）
PACKAGES=""

############# 核心基础组件 #############
PACKAGES="$PACKAGES curl openssh-sftp-server htop usbutils"

############# 存储管理全家桶 #############
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES e2fsprogs gdisk partclone badblocks"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn luci-app-ksmbd"  # SMBv3加速

############# DNS全矩阵方案 #############
PACKAGES="$PACKAGES luci-app-mosdns mosdns"                # DNS分流核心
PACKAGES="$PACKAGES luci-app-adguardhome"                 # 广告过滤
PACKAGES="$PACKAGES luci-app-smartdns bind-dig"            # 智能解析
PACKAGES="$PACKAGES dnsmasq-full luci-app-dnsfilter"       # 增强DNS

############# 科学上网全家桶 #############
PACKAGES="$PACKAGES luci-app-passwall"                    # 全协议支持
PACKAGES="$PACKAGES luci-app-openclash"                   # 规则订阅
PACKAGES="$PACKAGES luci-app-homeproxy"                   # 新一代代理
PACKAGES="$PACKAGES luci-app-ssr-plus"                    # 兼容旧版

############# 网络加速套件 #############
PACKAGES="$PACKAGES luci-app-turboacc"                    # 全锥型NAT
PACKAGES="$PACKAGES luci-app-flowoffload"                 # 软路由加速
PACKAGES="$PACKAGES luci-app-sqm"                         # 智能QoS

############# 企业级服务组件 #############
# DDNS全家福
PACKAGES="$PACKAGES luci-app-ddns-go"                     # 新版DDNS
PACKAGES="$PACKAGES ddns-scripts-cloudflare ddns-scripts-aliyun"

# 内网穿透矩阵
PACKAGES="$PACKAGES luci-app-zerotier luci-app-tailscale"  # SD-WAN方案
PACKAGES="$PACKAGES luci-app-frpc luci-app-nps"            # 反向穿透

############# 云服务生态 #############
PACKAGES="$PACKAGES luci-app-filebrowser"                 # 文件管理
PACKAGES="$PACKAGES luci-app-nextcloud"                   # 私有云盘
PACKAGES="$PACKAGES luci-app-webdav"                      # 云同步

############# 系统监控矩阵 #############
PACKAGES="$PACKAGES luci-app-statistics"                  # 数据采集
PACKAGES="$PACKAGES collectd-mod-thermal"                  # 温度监控
PACKAGES="$PACKAGES luci-app-netdata"                     # 实时仪表盘
PACKAGES="$PACKAGES luci-app-nlbwmon"                      # 流量统计

############# 激活与授权服务 #############
PACKAGES="$PACKAGES luci-app-vlmcsd vlmcsd"               # KMS激活
PACKAGES="$PACKAGES luci-app-unblockneteasemusic"         # 音乐解锁

############# 全主题生态 #############
PACKAGES="$PACKAGES luci-theme-argon"                     # 热门主题
PACKAGES="$PACKAGES luci-theme-material"                  # 质感设计
PACKAGES="$PACKAGES luci-theme-edge"                      # 极简风格
PACKAGES="$PACKAGES luci-theme-neobird"                   # 霓虹灯效
PACKAGES="$PACKAGES luci-theme-opentomcat"                # 复古风格

############# 生产力工具集 #############
PACKAGES="$PACKAGES luci-app-aria2"                      # 下载工具
PACKAGES="$PACKAGES luci-app-transmission"               # BT下载
PACKAGES="$PACKAGES luci-app-qbittorrent"                # 增强BT
PACKAGES="$PACKAGES luci-app-jd-dailybonus"               # 自动签到
PACKAGES="$PACKAGES luci-app-atinout-mod"                 # 短信控制

############# Docker全栈支持 #############
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    PACKAGES="$PACKAGES dockerd docker-compose docker-volume-netshare"
    PACKAGES="$PACKAGES docker-ce"                        # 企业版引擎
fi

############# iStore生态依赖 #############
PACKAGES="$PACKAGES luci-app-store"                       # 应用商店
PACKAGES="$PACKAGES luci-lib-ipkg" 

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
