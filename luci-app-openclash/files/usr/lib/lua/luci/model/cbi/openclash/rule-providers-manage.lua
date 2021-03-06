
local form, m
local openclash = "openclash"
local NXFS = require "nixio.fs"
local SYS  = require "luci.sys"
local HTTP = require "luci.http"
local DISP = require "luci.dispatcher"
local UTIL = require "luci.util"
local fs = require "luci.openclash"
local uci = require "luci.model.uci".cursor()

m = SimpleForm("openclash", translate("Other Rule Providers List"))
m.description=translate("规则项目: Profiles ( https://github.com/DivineEngine/Profiles )<br/>")
m.reset = false
m.submit = false

local t = {
    {Apply}
}

a = m:section(Table, t)

o = a:option(Button, "Refresh")
o.inputtitle = translate("Refresh Page")
o.inputstyle = "apply"
o.write = function()
  HTTP.redirect(DISP.build_url("admin", "services", "openclash", "rule-providers-manage"))
end

o = a:option(Button, "Apply")
o.inputtitle = translate("Back Configurations")
o.inputstyle = "reset"
o.write = function()
  HTTP.redirect(DISP.build_url("admin", "services", "openclash", "rule-settings"))
end

if not NXFS.access("/tmp/rule_providers_name") then
   SYS.call("awk -F ',' '{print $5}' /etc/openclash/rule_providers.list > /tmp/rule_providers_name 2>/dev/null")
end
file = io.open("/tmp/rule_providers_name", "r");

---- Rules List
local e={},o,t
if NXFS.access("/tmp/rule_providers_name") then
for o in file:lines() do
table.insert(e,o)
end
for t,o in ipairs(e) do
e[t]={}
e[t].num=string.format(t)
e[t].name=string.sub(luci.sys.exec(string.format("grep -F ',%s' /etc/openclash/rule_providers.list |awk -F ',' '{print $1}' 2>/dev/null",o)),1,-2)
e[t].filename=string.sub(luci.sys.exec(string.format("grep -F ',%s' /etc/openclash/rule_providers.list |awk -F ',' '{print $6}' 2>/dev/null",o)),1,-2)
if e[t].filename == "" then
e[t].filename=o
end
e[t].author=string.sub(luci.sys.exec(string.format("grep -F ',%s' /etc/openclash/rule_providers.list |awk -F ',' '{print $2}' 2>/dev/null",o)),1,-2)
e[t].rule_type=string.sub(luci.sys.exec(string.format("grep -F ',%s' /etc/openclash/rule_providers.list |awk -F ',' '{print $3}' 2>/dev/null",o)),1,-2)
RULE_FILE="/etc/openclash/rule_provider/".. e[t].filename
if fs.mtime(RULE_FILE) then
e[t].mtime=os.date("%Y-%m-%d %H:%M:%S",fs.mtime(RULE_FILE))
else
e[t].mtime="/"
end
if fs.isfile(RULE_FILE) then
   e[t].exist=translate("Exist")
else
   e[t].exist=translate("Not Exist")
end
e[t].remove=0
end
end
file:close()

form=SimpleForm("filelist")
form.reset=false
form.submit=false
tb=form:section(Table,e)
nu=tb:option(DummyValue,"num",translate("Order Number"))
st=tb:option(DummyValue,"exist",translate("State"))
st.template="openclash/cfg_check"
tp=tb:option(DummyValue,"rule_type",translate("Rule Type"))
nm=tb:option(DummyValue,"name",translate("Rule Name"))
au=tb:option(DummyValue,"author",translate("Rule Author"))
fm=tb:option(DummyValue,"filename",translate("File Name"))
mt=tb:option(DummyValue,"mtime",translate("Update Time"))

btnis=tb:option(DummyValue,"filename",translate("Download Rule"))
btnis.template="openclash/download_rule"

btnrm=tb:option(Button,"remove",translate("Remove"))
btnrm.render=function(e,t,a)
e.inputstyle="reset"
Button.render(e,t,a)
end
btnrm.write=function(a,t)
fs.unlink("/etc/openclash/rule_provider/"..e[t].filename)
HTTP.redirect(DISP.build_url("admin", "services", "openclash", "game-rules-manage"))
end

return m, form
