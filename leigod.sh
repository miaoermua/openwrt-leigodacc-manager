#!/bin/sh

# Check ROOT & OpenWrt
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use root user"
    exit 1
fi

# Prevent Xiaomi Routers and Qunou Routers from running openwrt-leigodacc-manager
if [ -e /etc/asus_release ]; then
    echo "TONY 别肘! 我爱 BCM!"
    echo ""
    echo "[ERROR] 检测到 ASUS 路由器，无法运行 OpenWrt LeigodAcc 管理器，你不是 OpenWrt 系统!"

    if [ ! -d /jffs/softcenter ]; then
        echo "[INFO] 检测到官改 or Koolcenter 版本，即将脱离 OpenWrt 管理器运行官方脚本开始安装."
        echo "[INFO] 以下内容均与 OpenWrt 管理器作者无关，本人并无华硕路由器 Debug!"
        echo
        sleep 5
        cd /tmp || { echo "[ERROR] 无法切换到 /tmp 目录"; exit 1; }
        sh -c "$(curl -fsSL http://119.3.40.126/router_plugin/plugin_install.sh)"

    fi
    exit 0
fi

if [ -d /userdisk/appdata ]; then
    echo "R u OK?"
    echo ""
    echo "[ERROR] 检测到小米路由器，无法运行 OpenWrt LeigodAcc 管理器，你不是 OpenWrt 系统!"
    local name=$(uci get misc.hardware.displayName 2>/dev/null)
    if [[ $? != "0" || -z ${name} ]]; then
        name=$(uci get misc.hardware.model 2>/dev/null)
    fi
    if [[ -n ${name} ]]; then
        echo "[INFO] 小米路由器: ${name}"
        sleep 5
        echo "[INFO] 检测到小米已经解锁了 SSH，即将脱离 OpenWrt 管理器运行官方脚本开始安装."
        echo "[INFO] 以下内容均与 OpenWrt 管理器作者无关，本人并无小米路由器 Debug!"
        echo
        cd /tmp || { echo "[ERROR] 无法切换到 /tmp 目录"; exit 1; }
        sh -c "$(curl -fsSL http://119.3.40.126/router_plugin/plugin_install.sh)"
        exit 0
    fi
fi


if ! grep -qi -E "OpenWrt|LEDE|QWRT|ImmortalWrt|iStoreOS" /etc/openwrt_release; then
    echo "Your system is not supported!"
    echo "[INFO]你的系统可能无法运行 OpenWrt Leigodacc 插件!"
    echo "当前系统环境并非常见或标准的 OpenWrt，可能是论坛版本修改发行版文件导致无法识别"
    echo "可能导致无法正常支持全部依赖，部分组件可能无法正常启用导致加速问题"
    echo "你可以无视风险继续安装，5s 后将进入管理器菜单，详情参考管理器发布于博客信息"
    echo
    sleep 5
fi

leigod_menu() {
    echo
    echo "============================="
    echo "OpenWrt LeigodAcc Manager"
    echo
    echo "1. 安装"
    echo "2. 卸载"
    echo "3. 重装/更新"
    echo "4. 禁用/启用 雷神服务"
    echo "5. 切换运行模式   (TUN/Tproxy)"
    echo "6. 安装兼容性依赖 (主机优化)"
    echo "7. 禁用/启用 IPv6 (手机优化)"
    echo "8. 安装 Lean IPKG 版"
    echo "9. 反馈/帮助"
    echo "0. 退出"
    echo "============================="
    echo -n "选择数字功能项并回车执行: "
}

install_leigodacc() {
    if [ -d /usr/sbin/leigod ]; then
        echo -n "[INFO] 检测到已经安装 LeigodAcc ([1]继续安装 / [2]取消): "
        read choice
        case $choice in
            1)
                ;;
            2)
                return
                ;;
            *)
                echo "[ERROR] 无效的选项，请重新输入"
                return
                ;;
        esac
    fi

    if [ -f /etc/catwrt_release ]; then
        if ! grep -q -E "catwrt|repo.miaoer.xyz" /etc/opkg/distfeeds.conf && ! ip a | grep -q -E "192\.168\.[0-9]+\.[0-9]+|10\.[0-9]+\.[0-9]+\.[0-9]+|172\.1[6-9]\.[0-9]+\.[0-9]+|172\.2[0-9]+\.[0-9]+|172\.3[0-1]\.[0-9]+\.[0-9]+"; then
            echo "[ERROR] 检测到 CatWrt，请先配置 CatWrt 软件源，请使用:"
            echo "Cattools - Apply_repo"
            echo
            echo "在正确启用软件源后即可获取雷神加速器插件完整支持(可能)"
            cattools
            return
        fi
    else
        echo "cat /etc/opkg/customfeeds.conf" && cat /etc/opkg/customfeeds.conf
        echo "cat /etc/opkg/distfeeds.conf" && cat /etc/opkg/distfeeds.conf
        if [ ! -f /usr/bin/cattools ]; then
            echo "[AD] 你还没有安装 Cattools 以方便安装 LeigodAcc 中依赖部分缺少的组件"
            echo "请查看 https://github.com/miaoermua/cattools 或使用"
            echo "推荐 CatWrt 最新版 https://www.miaoer.net/network/catwrt"
            echo ""
        fi
    fi

    release_info=$(cat /etc/openwrt_release)
    if echo "$release_info" | grep -qE "iStoreOS|QWRT|ImmortalWrt|LEDE"; then
        echo "Detected third-party firmware: $(echo "$release_info" | grep -E "iStoreOS|QWRT|ImmortalWrt|LEDE")"
    fi

    [ -e /var/lock/opkg.lock ] && rm /var/lock/opkg.lock
    opkg update

    for pkg in libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-ipset ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 正在安装必备组件 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 必备组件已安装，跳过"
        fi
    done

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full conntrack; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 尝试安装 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    if ! opkg list-installed | grep -q 'luci-app-upnp'; then
        echo "[INFO] luci-app-upnp 未安装，正在安装..."
        opkg install luci-app-upnp
    fi

    if [ -f /etc/config/upnpd ]; then
        echo "[INFO] 正在启用 UPnP..."
        uci set upnpd.config.enabled='1'
        uci commit upnpd

        /etc/init.d/miniupnpd start
        /etc/init.d/miniupnpd enable

        echo "[INFO] UPnP 已启用并运行"
        echo "安装成功后可以在雷神加速器 APP 发现并绑定设备"
        echo
    else
        echo "[ERROR] UPnP 配置文件不存在，安装可能失败，请检查固件!"
        exit 1
    fi

    echo "[INFO] 下面是雷神官方提供的脚本,打印内容偏长如遇到问题请提供输出内容(截图/文字)反馈到群里."
    
    cd /tmp && sh -c "$(curl -fsSL http://119.3.40.126/router_plugin/plugin_install.sh)"

    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 检测到 LeigodAcc 未安装，有可能是设备存储空间已满或者雷神服务器挂了!"
        echo "请登录 OpenWrt 路由器后台: 系统-软件包 查看当前可用空间诊断."
    else
        echo "[INFO] LeigodAcc 已成功安装"
    fi

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset conntrack curl libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 缺少组件包: $pkg"
            echo "[INFO] 你可以通过管理器中的安装依赖性组件进行补充!"
        fi
    done
}

install_compatibility_dependencies() {
    arch=$(opkg print-architecture | grep "arch" | awk '{print $2}' | grep -v "all\|noarch")
    if [ -z "$arch" ]; then
        echo "[ERROR] 无法确定系统架构"
        return
    fi

    case "$arch" in
        x86_64)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/libnetfilter-cttimeout1_1.0.0-2_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/libnetfilter-cthelper0_1.0.0-2_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/base/tc-full_6.3.0-1_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/conntrackd_1.4.8-1_x86_64.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/x86_64/packages/conntrack_1.4.8-1_x86_64.ipk"
            ;;
        mipsel_24kc)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/conntrackd_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/conntrack_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/libnetfilter-cthelper0_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/packages/libnetfilter-cttimeout1_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mipsel_24kc/base/tc-full_6.3.0-1_mips_24kc.ipk"
            ;;
        aarch64_cortex-a53|aarch64_cortex-a53+crypto)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/base/tc-full_6.3.0-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/conntrack_1.4.8-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/conntrackd_1.4.8-1_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/libnetfilter-cttimeout1_1.0.0-2_aarch64_cortex-a53.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_cortex-a53/packages/libnetfilter-cthelper0_1.0.0-2_aarch64_cortex-a53.ipk"
            ;;
        aarch64_generic)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/conntrack_1.4.8-1_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/conntrackd_1.4.8-1_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/libnetfilter-cthelper0_1.0.0-2_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/packages/libnetfilter-cttimeout1_1.0.0-2_aarch64_generic.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/aarch64_generic/base/tc-full_6.3.0-1_aarch64_generic.ipk"
            ;;
        *)
            echo "[ERROR] 不支持的架构: $arch"
            return
            ;;
    esac

    for pkg in $packages; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 安装 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    for pkg in $packages; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] $pkg 未在官方源中找到，尝试使用第三方源"
            echo "[INFO] 正在使用天灵 immortalwrt pku 的软件源，并不是原生支持的软件包可能会存在你所在的第三方固件源除外的问题"
            for url in $urls; do
                wget -P "$tmp_dir" "$url"
            done
            opkg install "$tmp_dir"/*.ipk
            break
        fi
    done
    rm -rf "$tmp_dir"

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset conntrack curl libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[ERROR] 缺少包: $pkg"
            echo "Tip: 你可以到 immoralwrt 官网构建固件并勾选对应的组件替换掉当前系统,或者使用 CatWrt.v24.9 支持 LeigodAcc 全部依赖."
            echo "https://www.miaoer.net/posts/network/catwrt"
            echo
        fi
    done
}

uninstall_leigodacc() {
    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    echo "[INFO] 确定卸载? 输入数字后回车或 10s 后自动卸载 ([1]确定 / [2]取消): "
    read -t 10 choice
    case $choice in
        1)
            ;;
        2)
            return
            ;;
        *)
            ;;
    esac

    if opkg list_installed | grep -q "leigod-acc"; then
        echo "[INFO] leigod-acc 通过 opkg 安装，正在卸载"
        /etc/init.d/acc disable
        /etc/init.d/acc stop
        opkg remove luci-i18n-leigod-acc-zh-cn luci-app-leigod-acc leigod-acc
        rm -rf /usr/lib/lua/luci/model/cbi/leigod
        rm -rf /usr/lib/lua/luci/view/leigod
        rm -rf /usr/sbin/leigod
        rm -rf /tmp/luci-*
        echo "[INFO] leigod-acc 卸载成功"
    else
        rm /etc/config/accelerator
        /etc/init.d/acc disable
        /etc/init.d/acc stop
        rm /etc/init.d/acc
        rm /usr/lib/lua/luci/controller/acc.lua
        rm -rf /usr/lib/lua/luci/model/cbi/leigod
        rm -rf /usr/lib/lua/luci/view/leigod
        rm -rf /usr/sbin/leigod
        rm /usr/lib/lua/luci/i18n/acc.zh-cn.lmo
        rm -rf /tmp/luci-*
        echo "[INFO] LeigodAcc 卸载成功"
    fi
}

reinstall_leigodacc() {
    uninstall_leigodacc
    install_leigodacc
}

service() {
    if [ ! -f /etc/init.d/acc ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    if /etc/init.d/acc enabled; then
        /etc/init.d/acc disable
        /etc/init.d/acc stop
        echo "[INFO] LeigodAcc 服务已禁用并关闭"
    else
        /etc/init.d/acc enable
        /etc/init.d/acc start
        echo "[INFO] LeigodAcc 服务已启用并启动"
    fi
}

switch_mode() {
    if [ ! -f /etc/init.d/acc ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    if opkg list-installed | grep -q "^leigod-acc"; then
        current_tun=$(uci get accelerator.base.tun 2>/dev/null)

        if [ "$current_tun" = "1" ]; then
            uci set accelerator.base.tun='0'
            echo "[INFO] 已切换为 tproxy 模式"
        else
            uci set accelerator.base.tun='1'
            echo "[INFO] 已切换为 tun 模式"
        fi

        uci commit accelerator
    else
        if grep -q -- "--mode tun" /etc/init.d/acc; then
            sed -i 's|--mode tun|${args}|' /etc/init.d/acc
            echo "[INFO] 已切换为 tproxy 模式"
        else
            sed -i 's|${args}|--mode tun|' /etc/init.d/acc
            echo "[INFO] 已切换为 tun 模式"
        fi
    fi
    /etc/init.d/acc stop
    /etc/init.d/acc start
    echo "[INFO] 已经重启 LeigodAcc 服务"
}

disabled_ipv6() {
    config_file="/etc/config/dhcp"
    option_dhcpv6=$(uci get dhcp.lan.dhcpv6)
    option_ra=$(uci get dhcp.lan.ra)

    if [ "$option_dhcpv6" = "disabled" ] && [ "$option_ra" = "disabled" ]; then
        uci set dhcp.lan.ra='server'
        uci set dhcp.lan.dhcpv6='server'
        uci delete dhcp.lan.ra_flags
        uci add_list dhcp.lan.ra_flags='managed-config'
        uci add_list dhcp.lan.ra_flags='other-config'
        echo "[INFO] IPv6 已启用"
        echo "[INFO] 该功能只在 LEDE/QWRT/CatWrt 中测试"
        echo "[INFO] 其他 OpenWrt 版本可能需要在 Luci 界面中启用其他 IPv6 选项以获取正常的 IPv6 网络支持"
    else
        uci delete dhcp.lan.ra_flags
        uci set dhcp.lan.ra='disabled'
        uci set dhcp.lan.dhcpv6='disabled'
        uci add_list dhcp.lan.ra_flags='none'
        echo "[INFO] IPv6 已禁用"
        echo "[INFO] iOS/Android 设备请忘记无线 Wi-Fi 网络再连接，插件内就会自动识别"
    fi

    uci commit dhcp
    /etc/init.d/odhcpd restart
}

install_lean_ipkg_version() {
    if opkg list_installed | grep -q "leigod-acc"; then
        echo "[INFO] leigod-acc 已安装，L 有大雕"
        return
    else
        echo "[INFO] leigod-acc 未安装"
        if [ -f /var/lock/opkg.lock ]; then
            rm /var/lock/opkg.lock
        fi
        opkg update
    fi

    if [ -d /usr/sbin/leigod ]; then
        echo -n "[INFO] 检测到已经安装 LeigodAcc 普通版本，请返回管理器卸载后再继续!"
        return
    fi

    required_packages="libpcap iptables kmod-ipt-nat iptables-mod-tproxy kmod-ipt-tproxy kmod-ipt-ipset ipset kmod-tun curl miniupnpd tc-full kmod-netem conntrack conntrackd"
    missing_packages=""

    echo "[INFO] 检查在线软件源中是否存在所有依赖包..."
    for package in $required_packages; do
        if ! opkg list | grep -q "^$package"; then
            echo "[ERROR] 在线软件源中缺少依赖包: $package"
            missing_packages="$missing_packages $package"
        fi
    done

    if [ -n "$missing_packages" ]; then
        echo "[ERROR] 检测到在线软件源中缺少的依赖包，无法继续安装: $missing_packages"
        echo "你的设备暂不支持 Lean 版 IPKG 插件，尝试使用第一方带有依赖的 CatWrt 来安装 IPKG 版本吧，或者使用管理器中的普通安装选项"
        echo "访问以下链接获取 mt7621 & amd64(x86_64) 版本"
        echo
        echo "https://www.miaoer.net/posts/network/catwrt"
        sleep 5
        return 1
    fi

    echo "[INFO] 所有依赖包已在在线软件源中找到，正在安装缺失的依赖包..."

    for package in $required_packages; do
        if ! opkg list_installed | grep -q "^$package"; then
            echo "[INFO] 安装依赖包: $package"
            opkg install "$package"
        fi
    done

    echo "[INFO] 所有依赖包已安装！"

    arch=`opkg print-architecture | awk 'END {print $2}'`

    if opkg list | grep -q "leigod-acc"; then
        echo "[INFO] 软件源中检测到 leigod-acc 插件，正在安装..."
        opkg install leigod-acc luci-app-leigod-acc luci-i18n-leigod-acc-zh-cn
        echo "[INFO] Lean 版本 leigod-acc 安装成功！"
    else
        echo "[INFO] 在线软件源中没有找到 leigod-acc 包，将下载并安装相应的插件"

        case "$arch" in
            "aarch64_cortex-a53"|"aarch64_cortex-a53+crypto")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_aarch64_cortex-a53.ipk"
                ;;
            "aarch64_generic")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_aarch64_generic.ipk"
                ;;
            "mipsel_24kc")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_mipsel_24kc.ipk"
                ;;
            "x86_64")
                url="https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/leigod-acc_1.3.0.30-1_x86_64.ipk"
                ;;
            *)
                echo "[ERROR] 不支持的架构: $arch"
                return 1
                ;;
        esac

        echo "[INFO] 正在下载 leigod-acc 包: $url"
        echo
        wget -P /tmp/upload "$url"
        wget -P /tmp/upload "https://mirror.ghproxy.com/https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/luci-app-leigod-acc_1-3_all.ipk"
        wget -P /tmp/upload "https://mirror.ghproxy.com/https://github.com/miaoermua/openwrt-leigodacc-manager/releases/download/v1.3/luci-i18n-leigod-acc-zh-cn_1-3_all.ipk"

        opkg install /tmp/upload/leigod-acc_*.ipk /tmp/upload/luci-app-leigod-acc_1-3_all.ipk /tmp/upload/luci-i18n-leigod-acc-zh-cn_1-3_all.ipk
        echo

    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 检测到 LeigodAcc 未安装，有可能是设备存储空间已满或者雷神服务器挂了!"
        echo "请登录 OpenWrt 路由器后台: 系统-软件包 查看当前可用空间诊断."
    else
         echo "[INFO] Lean IPKG 插件版 leigod-acc 已成功安装!"
        fi
    fi
    
    if ! opkg list-installed | grep -q 'luci-app-upnp'; then
        echo "[INFO] luci-app-upnp 未安装，正在安装..."
        opkg install luci-app-upnp
    fi

    if [ -f /etc/config/upnpd ]; then
        echo "[INFO] 正在启用 UPnP..."
        uci set upnpd.config.enabled='1'
        uci commit upnpd

        /etc/init.d/miniupnpd start
        /etc/init.d/miniupnpd enable

        echo "[INFO] UPnP 已启用并运行"
        echo "[INFO] 安装成功后可以在雷神加速器 APP 发现并绑定设备"
    else
        echo "[ERROR] UPnP 配置文件不存在，安装可能失败，请检查固件!"
        exit 1
    fi
}

check_logs() {
    if ! opkg list-installed | grep -q "^tc-full"; then
        return 0
    fi

    if grep -q "exec tc command failed" /tmp/acc/acc-gw.log-* && grep -q "No such file or directory" /tmp/acc/acc-gw.log-*; then
        echo "[ERROR] 检测到插件中的 tc-full 组件出现了 'exec tc command failed' 错误，可能是软件源或者固件提供的 tc-full 组件问题"
        echo "可能导致无法加速的问题，由于实装 tc-full 的用户过少，请自行测试加速问题或手动重装 tc-full 组件"
        echo "opkg update && opkg remove tc-full && opkg install tc-full"
        echo
        sleep 5
    fi
}

check_acceleration() {
    log_file="/tmp/acc/acc-gw.log-*.log"

    if [ ! -f "$log_file" ]; then
        return 1
    fi

    if ! grep -q "S5 UDP" "$log_file"; then
        return 1
    fi

    last_s5_udp_time=$(grep -Eo '^[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "$log_file" | tail -1)

    if [ -z "$last_s5_udp_time" ]; then
        return 1
    fi

    current_time=$(date +%s)
    log_time=$(date -d "$last_s5_udp_time" +%s)
    time_diff=$((current_time - log_time))

    if [ "$time_diff" -gt 20 ]; then
        echo "[INFO] 检测到 UDP 被成功代理，加速成功"
    fi
}

check_openclash_mode() {
    if ! pgrep -f "openclash" > /dev/null 2>&1; then
        echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与加速器冲突"
        return 0
    fi

    config_dir="/etc/openclash"
    config_files=$(ls "$config_dir"/*.yaml 2>/dev/null)

    if [ -z "$config_files" ]; then
        return 0
    fi

    for config_file in $config_files; do
        mode=$(grep -E "^mode:" "$config_file" | awk '{print $2}')
        enhanced_mode=$(grep -E "^ *enhanced-mode:" "$config_file" | cut -d':' -f2 | xargs)

        if [ -z "$mode" ] || [ -z "$enhanced_mode" ]; then
            continue
        fi

        if [ "$mode" = "rule" ] && [ "$enhanced_mode" = "redir-host" ];then
            if grep -q "^tun:" "$config_file"; then
                echo "[WARN] OpenClash 运行在 Redir-Host 但不是兼容模式(Tproxy)"
                echo "[WARN] 你需要调整 OpenClash 的运行模式为 ‘兼容’，请移除 TUN 配置以避免加速器冲突。"
                echo
                echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与加速器冲突"
            fi
        else
            echo "[WARN] OpenClash 运行在 Fake-IP 未处于兼容模式"
            echo "[WARN] 你需要调整 OpenClash 的运行模式为 ‘兼容’，请移除 Fake-IP 配置以避免加速器冲突"
            echo
            echo "[Tip] 当你 OpenClash 为兼容模式(Tproxy),Leigod 需要切换为 TUN 模式以避免与加速器冲突"
        fi
    done
}

check_openclash_mode
check_acceleration
check_logs

help() {
    echo ""
    echo "BLOG: https://www.miaoer.net/posts/blog/openwrt-leigodacc-manager"
    echo "BUG 反馈请加群: 632342113"
    echo "[Tip] LeigodAcc 特指雷神加速器，leigod-acc 特指 Lean 版雷神插件"
    echo ""
    echo "HELP："
    echo "1. 安装：安装 LeigodAcc"
    echo "2. 卸载：卸载 LeigodAcc"
    echo "3. 重装：重装 LeigodAcc"
    echo "4. 禁用/启用：禁用或启用 LeigodAcc 服务"
    echo "5. 切换运行模式：在 TUN 和 Tproxy 模式之间切换"
    echo "6. 安装兼容性依赖：尝试使用天灵 immoralwrt pku 源安装常见缺失依赖"
    echo "7. 禁用 IPv6: 可以使手机部分手机游戏也能正常加速，会禁用掉 IPv6 网络"
    echo "8. 切换为 Lean IPKG 版：可以通过 opkg 安装 leigod-acc 插件，为实验性版本"
    echo "9. 帮助：显示帮助信息"
    echo "0. 退出：退出管理器"
    echo ""
    sleep 3
}

while true; do
    leigod_menu
    read choice
    case $choice in
        1)
            install_leigodacc
            ;;
        2)
            uninstall_leigodacc
            ;;
        3)
            reinstall_leigodacc
            ;;
        4)
            service
            ;;
        5)
            switch_mode
            ;;
        6)
            install_compatibility_dependencies
            ;;
        7)
            disabled_ipv6
            ;;
        8)
            install_lean_ipkg_version
            ;;
        9)
            help
            ;;
        0)
            exit 0
            ;;
        *)
            echo "[ERROR] 请重新输入对应功能的数字并回车!"
            ;;
    esac
done
