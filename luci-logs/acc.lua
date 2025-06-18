module("luci.controller.acc", package.seeall)

function index()
  require("luci.i18n")
  entry({ "admin", "services", "acc" }, alias("admin", "services", "acc", "notice"), translate("Leigod Acc"), 50)
  entry({ "admin", "services", "acc", "notice" }, cbi("leigod/notice"), translate("Leigod Notice"), 10).i18n = "acc"
  entry({ "admin", "services", "acc", "service" }, cbi("leigod/service"), translate("Leigod Service"), 30).i18n = "acc"
  entry({ "admin", "services", "acc", "device" }, cbi("leigod/device"), translate("Leigod Device"), 50).i18n = "acc"
  entry({ "admin", "services", "acc", "status" }, call("get_acc_status")).leaf = true
  entry({ "admin", "services", "acc", "start_acc_service" }, call("start_acc_service"))
  entry({ "admin", "services", "acc", "stop_acc_service" }, call("stop_acc_service"))
  entry({ "admin", "services", "acc", "log" }, template("leigod/logs"), translate("Logs"), 70)
  entry({ "admin", "services", "acc", "get_log" }, call("get_log"))
end

-- get_acc_status get acc status
function get_acc_status()
  -- util module
  local util      = require "luci.util"
  local uci       = require "luci.model.uci".cursor()
  local translate = luci.i18n.translate
  -- init result
  local resp      = {}
  -- init state
  resp.service    = translate("Acc Service Disabled")
  resp.state      = {}
  -- check if exist
  local exist     = util.exec("ps | grep acc-gw | grep -v grep")
  -- check if program is running
  if exist ~= "" then
    resp.service = translate("Acc Service Enabled")
  end
  -- get uci
  local results = uci:get_all("accelerator")
  for _, typ in pairs({ "Phone", "PC", "Game", "Unknown" }) do
    local state = uci:get("accelerator", typ, "state")
    -- check state
    local state_text = "None"
    if state == nil or state == '0' then
    elseif state == '1' then
      state_text = translate("Acc Catalog Started")
    elseif state == '2' then
      state_text = translate("Acc Catalog Stopped")
    elseif state == '3' then
      state_text = translate("Acc Catalog Paused")
    end
    -- store text
    resp.state[translate(typ .. "_Catalog")] = state_text
  end
  luci.http.prepare_content("application/json")
  luci.http.write_json(resp)
end

-- start_acc_service
function start_acc_service()
  -- util module
  local util      = require "luci.util"
  util.exec("/etc/init.d/acc restart")
  local resp = {}
  resp.result = "OK"
  luci.http.prepare_content("application/json")
  luci.http.write_json(resp)  
end

-- start_acc_service
function stop_acc_service()
  -- util module
  local util      = require "luci.util"
  util.exec("/etc/init.d/acc stop")
  local resp = {}
  resp.result = "OK"
  luci.http.prepare_content("application/json")
  luci.http.write_json(resp)  
end

-- logs
function get_log()
    local log_file = "/tmp/acc/acc-gw.log-*"
    local tmpfile = os.tmpname()

    os.execute("cat " .. log_file .. " > " .. tmpfile .. " 2>/dev/null")

    local f = io.open(tmpfile, "r")
    if not f then
        print("Content-Type: text/plain\n")
        print("没有任何日志信息")
        return
    end

    local content = f:read("*a")
    f:close()
    os.remove(tmpfile)

    if #content == 0 then
        print("Content-Type: text/plain\n")
        print("没有任何日志信息")
    else
        print("Content-Type: text/plain\n")
        print(content)
    end
end