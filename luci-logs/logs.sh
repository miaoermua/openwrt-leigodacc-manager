#!/bin/sh

# Check ROOT & OpenWrt
if [ "$(id -u)" != "0" ]; then
    echo "Error: You must be root to run this script, please use root user"
    exit 1
fi

if [ ! -d "/usr/sbin/leigod" ]; then
    echo "[ERROR] 尚未安装雷神加速器插件"
    exit 1
fi

ACC_LUA_PATH="/usr/lib/lua/luci/controller/acc.lua"
if [ ! -f "$ACC_LUA_PATH" ]; then
    echo "[ERROR] 无法继续更新 LuCI 页面"
    exit 1
fi

ACC_LUA_URL="https://raw.miaoer.net/openwrt-leigodacc-manager/luci-logs/acc.lua" 
LOGS_HTM_URL="https://raw.miaoer.net/openwrt-leigodacc-manager/luci-logs/logs.htm" 
LOGS_HTM_PATH="/usr/lib/lua/luci/view/leigod/logs.htm"

mkdir -p /usr/lib/lua/luci/view/leigod/

wget -q -O "$ACC_LUA_PATH" "$ACC_LUA_URL"
if [ $? -ne 0 ]; then
    echo "[ERROR] 下载 $ACC_LUA_URL 失败，请检查网络连接"
    exit 1
fi

wget -q -O "$LOGS_HTM_PATH" "$LOGS_HTM_URL"
if [ $? -ne 0 ]; then
    echo "[ERROR] 下载 $LOGS_HTM_URL 失败，请检查网络连接"
    exit 1
fi

rm -rf /tmp/luci-*
/etc/init.d/uhttpd restart
echo "已添加 logs 页面，可通过 Luci 后台进行查看日志操作，方便排障。"
