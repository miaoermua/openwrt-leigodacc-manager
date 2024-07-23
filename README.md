# openwrt-leigodacc-manager

基于 shell 脚本的雷神加速器插件管理器，适用于 OpenWrt 系统

- [x] 支持第三方 OpenWrt 安装雷神加速器插件
- [x] 自动安装雷神依赖，支持启用天灵 ImmoralWrt 软件源安装部分缺失依赖
- [x] 支持修改雷神加速器运行模式(TUN/Tproxy)
- [x] 支持手机加速优化(禁用 IPv6)
- [x] 支持主机加速优化 NAT 类型检测(安装依赖组件)
- [ ] 不支持和 Proxy 插件共存(同时启用表现形式会断网)


执行下列命令 **使用 Leigod Acc Manager**

```sh
sh -c "$(curl -fsSL https://fastly.jsdelivr.net/gh/miaoermua/openwrt-leigodacc-manager@main/leigod.sh)"
```

> 此方法安装的不受 opkg 包管理器管理，无法通过 opkg 卸载雷神插件

该方法基于雷神加速器官方教程编写，管理程序开源不涉及商业竞争版权由 ©️ 雷神（武汉）网络技术有限公司 所有

## 已知问题

对应 pkg 包不存在，请换支持的固件彻底解决，如果是非必要组件可以不安装自适应。

```shell
Unknown package 'pkg'.
Collected errors:
 * opkg_install_cmd: Cannot install package pkg.
```

[Cattools](https://github.com/miaoermua/cattools) 是 [CatWrt](https://github.com/miaoermua/CatWrt) 专属工具箱可以实现软件源配置，CatWrt 必须启用后才能安装组件。

```shell
[ERROR] 请先配置软件源
Cattools - Apply_repo
```

**无网** 暂时不支持和 Proxy 性质插件共存，请关闭 Proxy 插件。

## 组件

只需要极客玩家及开发者了解，小白用户无需留意插件会自动安装可以安装的。

必要组件（影响插件运行）

```
libpcap
iptables
kmod-ipt-nat
iptables-mod-tproxy
tc-full
kmod-ipt-ipset
ipset
kmod-tun
curl
```

非必要组件（影响游戏内 PING 值，影响 NAT 类型检测）

```
kmod-ipt-tproxy
kmod-netem
conntrack
```
