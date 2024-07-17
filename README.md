# openwrt-leigodacc-manager

一个基于 sh 管理雷神插件的快捷工具

- [x] 支持第三方 OpenWrt 安装雷神加速器插件
- [x] 自动安装雷神依赖
- [ ] 不支持和 Proxy 共存(同时启用)
- [ ] 不支持修改雷神加速器为 TUN 模式，默认为 Tproxy

执行下列命令 **使用 Leigod Acc Manager**

```sh
sh -c "$(curl -fsSL https://fastly.jsdelivr.net/gh/miaoermua/openwrt-leigodacc-manager@main/leigod_menu.sh)"
```

> 此方法安装的不受 opkg 包管理器管理，无法通过 opkg 卸载雷神插件

该方法基于雷神加速器官方教程编写，管理程序开源不涉及商业竞争版权由 ©️ 雷神（武汉）网络技术有限公司 所有
