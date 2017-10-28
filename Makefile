#
# Copyright (C) 2017 OpenWrt-ssr
# Copyright (C) 2017 yushi studio <ywb94@qq.com>
#
# This is free software, licensed under the GNU General Public License v3.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=openwrt-ssr
PKG_VERSION:=1.2.1
#PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=https://github.com/chengxie/shadowsocks-libev
PKG_SOURCE_VERSION:=11db1d5e48f539855ea1a66947eba9bb9bc82150

PKG_SOURCE_PROTO:=git
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_LICENSE:=GPLv3
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=yushi studio <ywb94@qq.com>

#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)/$(BUILD_VARIANT)/$(PKG_NAME)-$(PKG_VERSION)

PKG_INSTALL:=1
PKG_FIXUP:=autoreconf
PKG_USE_MIPS16:=0
PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/package.mk

define Package/openwrt-ssr/Default
	SECTION:=luci
	CATEGORY:=LuCI
	SUBMENU:=3. Applications
	TITLE:=shadowsocksR-libev LuCI interface
	URL:=https://github.com/chengxie/openwrt-ssr
	VARIANT:=$(1)
	DEPENDS:=$(3)	
	PKGARCH:=all
endef


Package/luci-app-shadowsocksR = $(call Package/openwrt-ssr/Default,openssl,(OpenSSL),+libopenssl +libpthread +ipset +ip +iptables-mod-tproxy +libpcre +zlib +coreutils +coreutils-base64)

define Package/openwrt-ssr/description
	LuCI Support for $(1).
endef

Package/luci-app-shadowsocksR/description = $(call Package/openwrt-ssr/description,shadowsocksr-libev Client)

define Package/openwrt-ssr/prerm
#!/bin/sh
# check if we are on real system
if [ -z "$${IPKG_INSTROOT}" ]; then
    echo "Removing rc.d symlink for shadowsocksr"
     /etc/init.d/shadowsocksr disable
     /etc/init.d/shadowsocksr stop
    echo "Removing firewall rule for shadowsocksr"
	  uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocksr
		commit firewall
EOF
fi
exit 0
endef

Package/luci-app-shadowsocksR/prerm = $(call Package/openwrt-ssr/prerm,shadowsocksr)

define Package/openwrt-ssr/postinst
#!/bin/sh

if [ -z "$${IPKG_INSTROOT}" ]; then
	uci -q batch <<-EOF >/dev/null
		delete firewall.shadowsocksr
		set firewall.shadowsocksr=include
		set firewall.shadowsocksr.type=script
		set firewall.shadowsocksr.path=/var/etc/shadowsocksr/firewall.include
		set firewall.shadowsocksr.reload=0
		commit firewall
EOF
fi

if [ -z "$${IPKG_INSTROOT}" ]; then
	( . /etc/uci-defaults/luci-shadowsocksr ) && rm -f /etc/uci-defaults/luci-shadowsocksr
	chmod 755 /etc/init.d/shadowsocksr >/dev/null 2>&1
	/etc/init.d/shadowsocksr enable >/dev/null 2>&1
fi
exit 0
endef


Package/luci-app-shadowsocksR/postinst = $(call Package/openwrt-ssr/postinst,shadowsocksr)

CONFIGURE_ARGS += --disable-documentation --disable-ssp

define Package/openwrt-ssr/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/controller
	$(INSTALL_DATA) ./files/luci/controller/$(2).lua $(1)/usr/lib/lua/luci/controller/$(2).lua
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) ./files/luci/i18n/$(2).*.lmo $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/model/cbi/shadowsocksr
	$(INSTALL_DATA) ./files/luci/model/cbi/shadowsocksr/*.lua $(1)/usr/lib/lua/luci/model/cbi/shadowsocksr/
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/view/shadowsocksr
	$(INSTALL_DATA) ./files/luci/view/shadowsocksr/*.htm $(1)/usr/lib/lua/luci/view/shadowsocksr/
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/root/etc/uci-defaults/luci-$(2) $(1)/etc/uci-defaults/luci-$(2)
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-redir $(1)/usr/bin/ssr-redir
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/ss-check $(1)/usr/bin/ssr-check
	$(INSTALL_BIN) ./files/shadowsocksr.rule $(1)/usr/bin/ssr-rules
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/shadowsocksr.config $(1)/etc/config/shadowsocksr
	$(INSTALL_DIR) $(1)/etc/shadowsocksr
	$(INSTALL_BIN) ./files/*.sh $(1)/etc/shadowsocksr/	
	$(INSTALL_DATA) ./files/china_chnroute.list $(1)/etc/shadowsocksr/china_chnroute.list	
	$(INSTALL_DIR) $(1)/etc/dnsmasq.d
	$(INSTALL_DATA) ./files/gfwlist.conf $(1)/etc/dnsmasq.d/gfwlist.conf
	$(INSTALL_DIR) $(1)/etc/crontabs
	$(INSTALL_DATA) ./files/crontab.root $(1)/etc/crontabs/root
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/shadowsocksr.init $(1)/etc/init.d/shadowsocksr
endef

Package/luci-app-shadowsocksR/install = $(call Package/openwrt-ssr/install,$(1),shadowsocksr)

$(eval $(call BuildPackage,luci-app-shadowsocksR))
