-- 微信工具库
local string = require("string")
local config = require("app.config.config")
local log = require("lapis.logging")
local json = require("cjson")
local redis = require("app.lib.redis")
local http = require("app.lib.http")
local helper = require("app.lib.helper")

local wechatUtil = {}

-- 校验微信签名是否正确
-- https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html#%E7%AC%AC%E4%BA%8C%E6%AD%A5%EF%BC%9A%E9%AA%8C%E8%AF%81%E6%B6%88%E6%81%AF%E7%9A%84%E7%A1%AE%E6%9D%A5%E8%87%AA%E5%BE%AE%E4%BF%A1%E6%9C%8D%E5%8A%A1%E5%99%A8
function wechatUtil.checkSignature(signature, timestamp, nonce, token)
    local t = {timestamp, nonce, token}
    table.sort(t)
    local raw = ""
    for i, v in ipairs(t) do
        raw = raw .. v
    end
    -- https://github.com/openresty/lua-resty-string
    local resty_sha1 = require "resty.sha1"

    local sha1 = resty_sha1:new()
    if not sha1 then
        ngx.say("failed to create the sha1 object")
        return false
    end

    local ok = sha1:update(raw)
    if not ok then
        ngx.say("failed to add data")
        return false
    end

    local digest = sha1:final()
    local restyString = require "resty.string"
    local calSign = restyString.to_hex(digest)
    return calSign == signature
end

function wechatUtil.getWechatOption()
    return {
        scheme = "https",
        host = "api.weixin.qq.com",
        port = "443",
    }
end

-- 获取accessToken
-- https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1421140183
function wechatUtil.getAccessToken()
    local red = redis.new()
    local accessToken, err = red:exec(function(red)
        return red:get("wechat:access_token")
    end)

    if not accessToken or accessToken == ngx.null then 
        local appId = config.wechat.appId
        local appSecret = config.wechat.appSecret
        local path = string.format("/cgi-bin/token?grant_type=client_credential&appid=%s&secret=%s",appId, appSecret)
        local httpi = http.new()
        local options = wechatUtil.getWechatOption()
        local res_body, res, err = httpi:exec(options, function(httpc)
            return httpc:request({
                method = "GET",
                path = path,
                headers = {["Content-Type"] = "application/json",},
            })
        end)
        if res_body == "" then
            ngx.log(ngx.ERR, "=============>request failed: ", err)
            return ""
        end

        local data = json.decode(res_body)
        red:exec(function(red)
            return red:setex("wechat:access_token", data.expires_in-100, data.access_token)
        end)
        accessToken = data.access_token
    end
    return accessToken
end

-- 发送消息
-- https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Service_Center_messages.html#%E5%AE%A2%E6%9C%8D%E6%8E%A5%E5%8F%A3-%E5%8F%91%E6%B6%88%E6%81%AF
function wechatUtil.sendMessage(body)
    local accessToken = wechatUtil.getAccessToken()
    if accessToken == "" then
        ngx.log(ngx.ERR, "accessToken get failed")
        return
    end

    local path = string.format("/cgi-bin/message/custom/send?access_token=%s",accessToken)
    local httpi = http.new()

    local options = wechatUtil.getWechatOption()
    local resBody, res, err = httpi:exec(options, function(httpc)
        return httpc:request({
            method = "POST",
            path = path,
            body = json.encode(body),
            headers = {["Content-Type"] = "application/json",},
        })
    end)
   
    if not res then
        ngx.log(ngx.ERR, "=============>send message request failed: ", err)
    end
    log.notice(resBody)
    
end


-- 获取ticket
-- https://mp.weixin.qq.com/wiki?t=resource/res_main&id=mp1443433542
function wechatUtil.getTicket()
    local accessToken = wechatUtil.getAccessToken()
    if accessToken == "" then
        ngx.log(ngx.ERR, "accessToken get failed")
        return nil
    end

    local path = string.format("/cgi-bin/qrcode/create?access_token=%s", accessToken)
    local httpi = http.new()
    local options = wechatUtil.getWechatOption()

    local scene_str = helper.getRandomStr(20)
    local body = {
        expire_seconds = 3600*24,
        action_name = "QR_SCENE",
        action_info = {
            scene = {
                scene_str = scene_str
            }
        }
    }
    local resBody, res, err = httpi:exec(options, function(httpc)
        return httpc:request({
            method = "POST",
            path = path,
            body = json.encode(body),
            headers = {["Content-Type"] = "application/json",},
        })
    end)
   
    if not res then
        ngx.log(ngx.ERR, "=============>send message request failed: ", err)
        return nil
    end
    log.notice(resBody)
    local ticketData = json.decode(resBody)
    ticketData.scene = scene_str
    return ticketData
end

return wechatUtil