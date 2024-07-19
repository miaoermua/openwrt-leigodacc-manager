#!/bin/sh

# Check ROOT & OpenWrt
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root user"
    exit 1
fi

if [ -e /etc/asus_release ]; then
    echo "TONY 别肘!我是说出台词我爱 BCM!"
    exit 0
fi

if ! grep -q "OpenWrt" /etc/openwrt_release; then
    echo "Your system is not supported!"
    exit 1
fi

leigod_menu() {
    echo "OpenWrt LeigodAcc Manager"
    echo ""
    echo "1. 安装"
    echo "2. 卸载"
    echo "3. 重装/更新"
    echo "4. 禁用/启用 雷神服务"
    echo "5. 切换运行模式 (TUN/Tproxy)"
    echo "6. 帮助"
    echo "0. 退出"
    echo ""
    echo "选择数字功能项并回车执行: "
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
            echo "[ERROR] 请先配置软件源"
            echo "Cattools - Apply_repo"
            cattools
            return
        fi
    else
        echo "/etc/opkg/customfeeds.conf"
        cat /etc/opkg/customfeeds.conf
        echo "/etc/opkg/distfeeds.conf"
        cat /etc/opkg/distfeeds.conf
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

    rm /var/lock/opkg.lock
    opkg update

    for pkg in libpcap iptables kmod-ipt-nat iptables-mod-tproxy ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 安装 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    for pkg in kmod-tun kmod-ipt-tproxy kmod-netem tc-full kmod-ipt-ipset; do
        if ! opkg list_installed | grep -q "$pkg"; then
            echo "[INFO] 尝试安装 $pkg"
            opkg install $pkg
        else
            echo "[INFO] $pkg 已安装，跳过"
        fi
    done

    echo "[INFO] 下面是官方脚本输出内容,如遇到问题请截图反馈官方"
    
    cd /tmp && sh -c "$(curl -fsSL http://119.3.40.126/router_plugin/plugin_install.sh)"
}

uninstall_leigodacc() {
    if [ ! -d /usr/sbin/leigod ]; then
        echo "LeigodAcc 未安装"
        return
    fi

    echo "确定卸载? 选择数字并回车 10s 后自动卸载 ([1] 确定 / [2] 取消) "
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
    if /etc/init.d/acc enabled; then
        /etc/init.d/acc disable
        /etc/init.d/acc stop
    else
        /etc/init.d/acc enable
        /etc/init.d/acc start
    fi
}

switch_mode() {
    grep -q -- "--mode tun" /etc/init.d/acc
    if [ $? -eq 0 ]; then
        current_mode="tun"
    else
        current_mode="tproxy"
    fi
    if [ "$current_mode" = "tproxy" ]; then
        sed -i "s/${args}/--mode tun/" /etc/init.d/acc
    else
        sed -i "s/--mode tun/${args}/" /etc/init.d/acc
    fi
    /etc/init.d/acc stop
    /etc/init.d/acc start
}

help() {
    echo "帮助信息："
    echo "1. 安装：安装 LeigodAcc"
    echo "2. 卸载：卸载 LeigodAcc"
    echo "3. 重装：重装 LeigodAcc"
    echo "4. 禁用/启用：禁用或启用 LeigodAcc 服务"
    echo "5. 切换运行模式：在 TUN 和 Tproxy 模式之间切换"
    echo "6. 帮助：显示帮助信息"
    echo "0. 退出：退出脚本"
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
            help
            ;;
        0)
            exit 0
            ;;
        *)
            echo "[ERROR] 无效的选项，请重新输入"
            ;;
    esac
done
