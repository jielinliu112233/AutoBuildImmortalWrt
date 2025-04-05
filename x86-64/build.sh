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
PACKAGES="$PACKAGES e2fsprogs gdisk"  # 移除 partclone 和 badblocks（体积大且使用率低）
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"  # 保留 SMBv3（移除 ksmbd 内核模块）

############# DNS全矩阵方案 #############
# 仅保留最稳定组合，避免多DNS服务冲突
PACKAGES="$PACKAGES dnsmasq-full luci-app-adguardhome"  # AdGuardHome 自带过滤功能
# PACKAGES="$PACKAGES luci-app-dnsfilter"  # 与 AdGuardHome 存在规则冲突风险

############# 科学上网全家桶 #############
# 仅保留一个核心代理工具（OpenClash 兼容性最佳）
PACKAGES="$PACKAGES luci-app-openclash"

############# 网络加速套件 #############
# TurboACC 已包含 Flow Offloading
PACKAGES="$PACKAGES luci-app-turboacc"  # 包含 Fullcone NAT + Flow Offload

############# 企业级服务组件 #############
# 保留基础 DDNS 和穿透工具
PACKAGES="$PACKAGES ddns-scripts-cloudflare"
PACKAGES="$PACKAGES luci-app-zerotier"  # 比 Tailscale 更稳定

############# 云服务生态 #############
# 仅保留轻量级文件管理
PACKAGES="$PACKAGES luci-app-filebrowser"  # 移除 Nextcloud（体积过大）

############# 系统监控矩阵 #############
PACKAGES="$PACKAGES luci-app-statistics collectd-mod-thermal"

############# 激活与授权服务 #############
PACKAGES="$PACKAGES luci-app-unblockneteasemusic"  # 保留音乐解锁

############# 全主题生态 #############
# 仅保留最流行主题
PACKAGES="$PACKAGES luci-theme-argon"  # 其他主题编译易出错

############# 生产力工具集 #############
# 移除所有签到/下载工具（依赖复杂）
# PACKAGES="$PACKAGES luci-app-aria2 luci-app-jd-dailybonus"

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
