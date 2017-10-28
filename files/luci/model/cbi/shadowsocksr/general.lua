-- Copyright (C) 2017 yushi studio <ywb94@qq.com> github.com/ywb94
-- Licensed to the public under the GNU General Public License v3.

local m, s, o
local shadowsocksr = "shadowsocksr"
local uci = luci.model.uci.cursor()
local servers = {}

local function has_bin(name)
	return luci.sys.call("command -v %s >/dev/null" %{name}) == 0
end

local function has_ssr_bin()
	return has_bin("ssr-redir")
end

local function has_udp_relay()
	return luci.sys.call("lsmod | grep -q TPROXY && command -v ip >/dev/null") == 0
end

local has_redir = has_ssr_bin()

if not has_redir then
	return Map(shadowsocksr, "%s - %s" %{translate("ShadowSocksR"),
		translate("General Settings")}, '<b style="color:red">shadowsocksr-libev binary file not found.</b>')
end

local function tcp_is_running()
	local ret = luci.sys.call("pidof ssr-redir >/dev/null") == 0
	return ret and translate("Running") or translate("Not Running")
end

local function udp_is_running()
	local reudp_1 = luci.sys.exec("ps -w | grep ssr-redir-udp- |grep -v grep| wc -l")
	local reudp_2 = luci.sys.exec("ps -w | grep ssr-redir- |grep \"\\-u\"|grep -v grep| wc -l")
	local ret = (tonumber(reudp_1) > 0 or tonumber(reudp_2) > 0)
	return ret and translate("Running") or translate("Not Running")
end

uci:foreach(shadowsocksr, "servers", function(s)
	if s.server and s.server_port then
		servers[#servers+1] = {name = s[".name"], alias = s.alias or "%s:%s" %{s.server, s.server_port}}
	end
end)

m = Map(shadowsocksr, "%s - %s" %{translate("ShadowSocksR"), translate("General Settings")})
m.template = "shadowsocksr/general"

-- [[ Running Status ]]--
s = m:section(TypedSection, "general", translate("Running Status"))
s.anonymous = true

if has_redir then
	o = s:option(DummyValue, "_redir_status", translate("Transparent Proxy"))
	o.value = "<span id=\"_redir_status\">%s</span>" %{tcp_is_running()}
	o.rawhtml = true
	o = s:option(DummyValue, "_redir_udp_status", translate("UDP Relay")) 
	o.value = "<span id=\"_redir_udp_status\">%s</span>" %{udp_is_running()}
	o.rawhtml = true
end

-- [[ Global Setting ]]--
s = m:section(TypedSection, "general", translate("Global Settings"))
s.anonymous = true

o = s:option(Value, "startup_delay", translate("Startup Delay"))
o:value(0, translate("Not enabled"))
for _, v in ipairs({5, 10, 15, 25, 40}) do
	o:value(v, translatef("%u seconds", v))
end
o.datatype = "uinteger"
o.default = 0
o.rmempty = false

if has_redir then
	--o = s:option(DynamicList, "main_server", translate("Main Server"))
	--o.template = "shadowsocksr/dynamiclist"
	o = s:option(ListValue, "main_server", translate("Main Server"))
	o:value("nil", translate("Disable"))
	for _, s in ipairs(servers) do o:value(s.name, s.alias) end
	o.default = "nil"
	o.rmempty = false

	o = s:option(ListValue, "udp_relay_server", translate("UDP Relay Server"))
	if has_udp_relay() then
		o:value("nil", translate("Disable"))
		o:value("same", translate("Same as Main Server"))
		for _, s in ipairs(servers) do o:value(s.name, s.alias) end
	else
		o:value("nil", translate("Unusable - Missing iptables-mod-tproxy or ip"))
	end
	o.default = "nil"
	o.rmempty = false

	o = s:option(Value, "local_port", translate("Local Port"))
	o.datatype = "port"
	o.default = 1234
	o.rmempty = false

	o = s:option(Value, "mtu", translate("Override MTU"))
	o.datatype = "range(296,9200)"
	o.default = 1492
	o.rmempty = false
end

return m
