# openwrt-leigodacc-manager

基于 shell 脚本的雷神加速器插件管理器，适用于 OpenWrt 系统

[![Stars](https://m3-markdown-badges.vercel.app/stars/3/3/miaoermua/openwrt-leigodacc-manager)](https://github.com/miaoermua/openwrt-leigodacc-manager)
[![Issues](https://m3-markdown-badges.vercel.app/issues/1/2/miaoermua/openwrt-leigodacc-manager)](https://github.com/miaoermua/openwrt-leigodacc-manager/issues)
[![Support](https://ziadoua.github.io/m3-Markdown-Badges/badges/Sponsor/sponsor1.svg)](https://www.miaoer.net/sponsor)
[![COPYING](https://ziadoua.github.io/m3-Markdown-Badges/badges/LicenceGPLv2/licencegplv23.svg)](https://github.com/miaoermua/openwrt-leigodacc-manager/blob/main/LICENSE)

博客: https://www.miaoer.net/posts/blog/openwrt-leigodacc-manager

扩展内容(通用): https://www.miaoer.net/posts/blog/leigod-acc-router-plugin

相关项目：https://github.com/miaoermua/luci-app-leigod-acc

---

支持第一方 QWRT/CatWrt/LEDE、及第三方 OpenWrt 如 ImmoraliWrt/iStoreOS 安装雷神加速器插件

- [x] 支持第三方 OpenWrt 安装雷神加速器插件
- [x] 支持引导华硕/小米路由器到官方脚本 (看项目名字)
- [x] 自动安装雷神依赖，支持启用天灵 ImmoralWrt 软件源安装部分缺失依赖
- [x] 支持修改雷神加速器运行模式 (TUN/Tproxy)
- [x] 支持手机加速优化 (禁用 IPv6)
- [x] 支持主机加速优化 NAT 类型检测 (给第三方 OpenWrt 安装依赖组件)
- [x] 支持和 Proxy 插件共存，需要开启 TUN 模式 (不开启 TUN 模式同时启用表现形式会断网)
- [ ] 不建议和不支持论坛乱改系统文件的固件

执行下列命令 **使用 Leigod Acc Manager**

```sh
sh -c "$(curl -fsSL https://fastly.jsdelivr.net/gh/miaoermua/openwrt-leigodacc-manager@main/leigod.sh)"
```

> 此方法安装的不受 opkg 包管理器管理，无法通过 opkg 卸载雷神插件，IPKG Lean 版正在推进中 ✨ 点亮小星星可以吗

该方法基于雷神加速器官方教程编写，不涉及商业及版权由 雷神（武汉）网络技术有限公司 所有

使用喵二专属雷神加速器口令 `miaoer` 可获得 50 小时不可暂停体验时长，搭配 OpenWrt 端可实现 6 端加速 PC 兑换: 雷神加速器 - 右上角更多 - CDK/口令兑换 - 口令兑换时长输入 `miaoer` 兑换

<p align="center">
<img src="https://fastly.jsdelivr.net/gh/miaoermua/static@main/images/sponsor-leigod.webp">
</p>

---

## 已知问题

**对应 pkg 包不存在** 请换支持的固件彻底解决，如果是非必要组件可以不安装自适应。

```shell
Unknown package 'pkg'.
Collected errors:
 * opkg_install_cmd: Cannot install package pkg.
```

<br>

tc-full 出现 **'exec tc command failed'** 错误

可能是组件源码本身有问题，或者 Leigod 干掉了，请自行重装或测试，目前并没有稳定复现的方法。


<br>

[Cattools](https://github.com/miaoermua/cattools) 是 [CatWrt](https://github.com/miaoermua/CatWrt) 专属工具箱可以实现 **软件源配置**，CatWrt 必须启用后才能安装组件。

```shell
[ERROR] 请先配置软件源
Cattools - Apply_repo
```

<br>

**无网** 暂时不支持和 Proxy 性质插件共存，请关闭 Proxy 插件

<br>

本插件可能无法在 **firewall4(nftables)** 环境下运行

关于网络结构差异导致的无法连接已安装插件的路由器设备，可以参考 [扩展内容](https://www.miaoer.net/posts/blog/leigod-acc-router-plugin#%E6%97%A0%E6%B3%95%E8%BF%9E%E6%8E%A5/%E6%97%A0%E6%B3%95%E8%AF%86%E5%88%AB%E8%AE%BE%E5%A4%87)。

## 组件

只需要极客玩家及开发者了解，小白用户无需留意插件会自动安装可以安装的。

必要组件（影响插件运行）

```
libpcap
iptables
kmod-ipt-nat
iptables-mod-tproxy
kmod-ipt-tproxy
kmod-ipt-ipset
ipset
kmod-tun
curl
miniupnpd
```

非必要组件（影响游戏内 PING 值，影响 NAT 类型检测）

```
tc-full
kmod-netem
conntrack
conntrackd
```
