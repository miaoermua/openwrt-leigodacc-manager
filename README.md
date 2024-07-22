# openwrt-leigodacc-manager

一个基于 shell 脚本管理雷神插件的快捷工具，适用于 OpenWrt 系统

- [x] 支持第三方 OpenWrt 安装雷神加速器插件
- [x] 自动安装雷神依赖
- [x] 支持修改雷神加速器为 TUN 模式，默认为 Tproxy
- [ ] 不支持和 Proxy 共存(同时启用)


执行下列命令 **使用 Leigod Acc Manager**

```sh
sh -c "$(curl -fsSL https://fastly.jsdelivr.net/gh/miaoermua/openwrt-leigodacc-manager@main/leigod_menu.sh)"
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

## 组件

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

非必要组件（影响游戏内 PING 值）

```
kmod-ipt-tproxy
kmod-netem
```
