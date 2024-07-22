#!/bin/sh

# Check ROOT & OpenWrt
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use root user"
    exit 1
fi

if [ -e /etc/asus_release ]; then
    echo "TONY 别肘!我爱 BCM!"
    echo ""
    echo "无法运行 OpenWrt LeigodAcc 管理器"
    echo "此脚本不适用于 ASUS 请在梅改固件中使用传统方法安装"
    exit 0
fi

if ! grep -q "OpenWrt" /etc/openwrt_release; then
    echo "Your system is not supported!"
    echo "别逗，你的系统无法运行 OpenWrt LeigodAcc 管理器!"
    exit 1
fi

leigod_menu() {
    echo ""
    echo "============================="
    echo "OpenWrt LeigodAcc Manager"
    echo ""
    echo "1. 安装"
    echo "2. 卸载"
    echo "3. 重装/更新"
    echo "4. 禁用/启用 雷神服务"
    echo "5. 切换运行模式 (TUN/Tproxy)"
    echo "6. 安装兼容性依赖 (主机优化)"
    echo "7. 反馈/帮助"
    echo "0. 退出"
    echo "============================="
    echo -n "选择数字功能项并回车执行: "
}

install_leigodacc() {
    if [ -d /usr/sbin/leigod ]; then
        echo "检测到已经安装 LeigodAcc"
        echo "选择 [1] 继续安装 / [2] 取消"
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
            echo "[ERROR] 请先配置 CatWrt 软件源"
            echo "Cattools - Apply_repo"
            cattools
            return
        fi
    else
        echo "cat /etc/opkg/customfeeds.conf" && cat /etc/opkg/customfeeds.conf
        echo "cat /etc/opkg/distfeeds.conf" && cat /etc/opkg/distfeeds.conf
        if [ ! -f /usr/bin/cattools ]; then
            echo "[AD] 你还没有安装 Cattools 以方便安装 LeigodAcc 中依赖 Kmod 的组件"
            echo "请查看 https://github.com/miaoermua/cattools 或使用"
            echo "推荐 CatWrt 最新版 https://www.miaoer.xyz/network/catwrt"
            echo ""
        fi
    fi

    release_info=$(cat /etc/openwrt_release)
    if echo "$release_info" | grep -qE "iStoreOS|QWRT|ImmortalWrt|LEDE"; then
        echo "Detected third-party firmware: $(echo "$release_info" | grep -E "iStoreOS|QWRT|ImmortalWrt|LEDE")"
    fi

    [ -e /var/lock/opkg.lock ] && rm /var/lock/opkg.lock
    opkg update

    for pkg in libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 正在安装必备组件 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 必备组件已安装，跳过"
        fi
    done

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset conntrack; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 尝试安装 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    echo "[INFO] 下面是雷神提供的脚本,打印内容偏长如遇到问题请提供输出内容(截图/文字)反馈到群里."
    
    cd /tmp && sh -c "$(curl -fsSL http://119.3.40.126/router_plugin/plugin_install.sh)"

    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 检测到 LeigodAcc 未安装，有可能是设备存储空间已满!"
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
        mips_24kc)
            packages="tc-full conntrack conntrackd libnetfilter-cttimeout1 libnetfilter-cthelper0"
            urls="https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mips_24kc/packages/conntrackd_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mips_24kc/packages/conntrack_1.4.8-1_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mips_24kc/packages/libnetfilter-cthelper0_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mips_24kc/packages/libnetfilter-cttimeout1_1.0.0-2_mips_24kc.ipk
            https://mirrors.pku.edu.cn/immortalwrt/releases/23.05.3/packages/mips_24kc/base/tc-full_6.3.0-1_mips_24kc.ipk"
            ;;
        aarch64_cortex-a53)
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
            echo "正在使用天灵 immortalwrt pku 的软件源，并不是原生支持的软件包可能会存在你所在的第三方固件源除外的问题"
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
            echo "Tip: 你可以到 immoralwrt 官网构建固件并勾选对应的组件,CatWrt 未来将支持 LeigodAcc 依赖."
        fi
    done
}

uninstall_leigodacc() {
    if [ ! -d /usr/sbin/leigod ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    echo "确定卸载? 输入数字后回车或 10s 后自动卸载 ([1]确定 / [2]取消): "
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
    else
        /etc/init.d/acc enable
        /etc/init.d/acc start
    fi
}

switch_mode() {
    if [ ! -f /etc/init.d/acc ]; then
        echo "[ERROR] 雷神服务文件不存在，是不是还没安装捏."
        return
    fi

    grep -q -- "--mode tun" /etc/init.d/acc
    if [ $? -eq 0 ]; then
        current_mode="tun"
    else
        current_mode="tproxy"
    fi
    if [ "$current_mode" = "tproxy" ]; then
        sed -i "s/${args}/--mode tun/" /etc/init.d/acc
    else
        sed -i "s/--mode tun/${args}/" /etc.init.d/acc
    fi
    /etc.init.d/acc stop
    /etc.init.d/acc start
}

help() {
    echo ""
    echo "BUG 反馈请加群: 632342113"
    echo "Tip: LeigodAcc 特指雷神加速器"
    echo ""
    echo "HELP："
    echo "1. 安装：安装 LeigodAcc"
    echo "2. 卸载：卸载 LeigodAcc"
    echo "3. 重装：重装 LeigodAcc"
    echo "4. 禁用/启用：禁用或启用 LeigodAcc 服务"
    echo "5. 切换运行模式：在 TUN 和 Tproxy 模式之间切换"
    echo "6. 安装兼容性依赖：尝试使用天灵 immoralwrt pku 源安装常见缺失依赖"
    echo "7. 帮助：显示帮助信息"
    echo "0. 退出：退出管理器"
    echo ""
    sleep 3
}

# 主程序
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
