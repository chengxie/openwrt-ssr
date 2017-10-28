ShadowsocksR-libev for OpenWrt
===

简介
---

 本项目是 shadowsocksr-libev 在OpenWrt上的移植  

 从ywb94的 https://github.com/ywb94/openwrt-ssr 的仓库fork出修改而来
 感谢ywb94 https://github.com/ywb94

 luci界面部分大量参考使用了他在 https://github.com/shadowsocks/luci-app-shadowsocks 中的代码
 感谢aa65535 https://github.com/aa65535
 

特性
---

软件包包含 shadowsocksr-libev 的可执行文件,以及luci控制界面  

支持SSR客户端与UDP中继；

客户端兼容运行SS或SSR的服务器，使用SS服务器时，传输协议需设置为origin，混淆插件需设置为plain

运行模式
---
 - 默认所有国内IP网段不走代理，国外IP网段走代理；
 - 白名单模式：缺省都走代理，列表中IP网段不走代理
 - 黑名单模式：缺省都不走代理，列表中网站走代理

dns防污染
---
 - 只支持IP路由模式，对现有OpenWRT系统改动较少；
 - 本地dns域名解析存在污染，由远端SSR服务器重新进行二次DNS解析；可和其他DNS处理软件一起使用；
 - 建议通过dnsmasq将gfwlist中的域名传递给dns-forwarder, 使用tcp的方式从代理隧道发送到ssr服务器上请求解析
 - forwarder如果没有安装dns-forwarder, 可以将dnsmasq.conf中的dnsmasq.d路径的配置去除，直接使用普通dns服务器

编译
---
 - 下载路由器对应平台的SDK

   ```bash
   # 以 ar71xx 平台为例
   tar xjf OpenWrt-SDK-15.05-ar71xx-generic_gcc-4.8-linaro_uClibc-0.9.33.2.Linux-x86_64.tar.bz2
   cd OpenWrt-SDK-*
   git clone https://github.com/chengxie/openwrt-ssr.git package/openwrt-ssr
   # 选择要编译的包 
   #luci ->3. Applications-> luci-app-shadowsocksR
   make menuconfig
   
   #如果没有安装po2lmo，则安装（可选）
   pushd package/openwrt-ssr/tools/po2lmo
   make && sudo make install
   popd
   #编译语言文件（可选）
   po2lmo ./package/openwrt-ssr/files/luci/i18n/shadowsocksr.zh-cn.po ./package/openwrt-ssr/files/luci/i18n/shadowsocksr.zh-cn.lmo
   
   # 开始编译
    make package/openwrt-ssr/compile V=99
   ```
   
安装
--- 
 - 本软件包依赖库：libopenssl、libpthread、ipset、ip、iptables-mod-tproxy、libpcre，GFW版本还需依赖dnsmasq-full、coreutils-base64，opkg会自动安装上述库文件


