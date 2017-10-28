-- Copyright (C) 2017 yushi studio <ywb94@qq.com>
-- Licensed to the public under the GNU General Public License v3.

module("luci.controller.shadowsocksr", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/shadowsocksr") then
		return
	end

	entry({"admin", "services", "shadowsocksr"}, 
		alias("admin", "services", "shadowsocksr", "general"), 
		_("ShadowSocksR"), 10).dependent = true

	entry({"admin", "services", "shadowsocksr", "general"}, 
		cbi("shadowsocksr/general"), 
		_("General Settings"), 10).leaf = true

 	entry({"admin", "services", "shadowsocksr", "access-control"},
		cbi("shadowsocksr/access-control"),
		_("Access Control"), 20).leaf = true

	entry({"admin", "services", "shadowsocksr", "servers"},
			arcombine(cbi("shadowsocksr/servers"), cbi("shadowsocksr/servers-editor")),
			_("Servers Manage"), 30).leaf = true
 
	entry({"admin", "services", "shadowsocksr", "tools"},
		cbi("shadowsocksr/tools"),
		_("Tools"), 40).leaf = true


	entry({"admin", "services", "shadowsocksr", "status"}, call("action_status")).leaf = true
	entry({"admin", "services", "shadowsocksr", "check"}, call("check_status"))
	entry({"admin", "services", "shadowsocksr", "refresh"}, call("refresh_data"))
	entry({"admin", "services", "shadowsocksr", "checkport"}, call("check_port"))

end

function check_status()
	local set ="/usr/bin/ssr-check www." .. luci.http.formvalue("set") .. ".com 80 3 1"
	sret=luci.sys.call(set)
	if sret== 0 then
		retstring ="0"
	else
		retstring ="1"
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring })
end

function refresh_data()
	local set =luci.http.formvalue("set")
	local icount =0
	if set == "gfw_data" then
		refresh_cmd="/etc/shadowsocksr/update_gfwlist.sh >> /var/log/update_gfwlist.log"
		sret = luci.sys.call(refresh_cmd .. " 2>/dev/null")
		if sret == 0 then
			icount = luci.sys.exec("cat /etc/dnsmasq.d/gfwlist.conf | wc -l")
			retstring = tostring(tonumber(icount))
		else
			retstring ="-1"
		end
	elseif set == "ip_data" then
		refresh_cmd="/etc/shadowsocksr/update_chnroute.sh >> /var/log/update_chnroute.log"
		sret = luci.sys.call(refresh_cmd .. " 2>/dev/null")
		icount = luci.sys.exec("cat /etc/shadowsocksr/china_chnroute.list | wc -l")
		if sret == 0 then
			retstring = tostring(tonumber(icount))
		else
			retstring ="-1"
		end
	end	
	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring ,retcount=icount})
end


function check_port()
	local set=""
	local retstring="<br /><br />"
	local s
	local server_name = ""
	local shadowsocksr = "shadowsocksr"
	local uci = luci.model.uci.cursor()
	local iret=1

	uci:foreach(shadowsocksr, "servers", function(s)

		if s.alias then
			server_name = s.alias
		elseif s.server and s.server_port then
			server_name = "%s:%s" %{s.server, s.server_port}
		end
		--iret = luci.sys.call(" ipset add ss_spec_wan_ac " .. s.server .. " 2>/dev/null")
		socket = nixio.socket("inet", "stream")
		socket:setopt("socket", "rcvtimeo", 3)
		socket:setopt("socket", "sndtimeo", 3)
		ret=socket:connect(s.server,s.server_port)
		if  tostring(ret) == "true" then
			socket:close()
			retstring =retstring .. "<font color='green'>[" .. server_name .. "] OK.</font><br />"
		else
			retstring =retstring .. "<font color='red'>[" .. server_name .. "] Error.</font><br />"
		end	
		--if iret == 0 then
			--luci.sys.call(" ipset del ss_spec_wan_ac " .. s.server)
		--end
	end)

	luci.http.prepare_content("application/json")
	luci.http.write_json({ ret=retstring })
end

local function tcp_is_running()
	return luci.sys.call("pidof ssr-redir >/dev/null") == 0
end

local function udp_is_running()
	local reudp_1 = luci.sys.exec("ps -w | grep ssr-redir-udp- |grep -v grep| wc -l")
	local reudp_2 = luci.sys.exec("ps -w | grep ssr-redir- |grep \"\\-u\"|grep -v grep| wc -l")
	return (tonumber(reudp_1) > 0 or tonumber(reudp_2) > 0)
end

function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		ssr_redir = tcp_is_running(),
		ssr_redir_udp = udp_is_running()
	})
end

