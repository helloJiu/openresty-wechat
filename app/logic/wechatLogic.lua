local setmetatable = setmetatable
local xmlParser = require("app.lib.xmlSimple"):newParser()
local helper = require("app.lib.helper")
local os = require("os")
local wechatUtil = require("app.lib.wechatUtil")
local log = require("lapis.logging")
local redis = require("app.lib.redis")

local logic = {}

function logic:New()
    local instance = {}
    setmetatable(instance, {
        __index = self
    })
    return instance
end

-- https://github.com/Cluain/Lua-Simple-XML-Parser

function logic:acceptMessage(input)
    log.notice("wechat input ==========>" .. input)
    local doc = xmlParser:ParseXmlText(input)
    local FromUserName = helper.parseCDATA(doc.xml.FromUserName:value());
    local ToUserName = helper.parseCDATA(doc.xml.ToUserName:value());
    -- local CreateTime = helper.parseCDATA(doc.xml.CreateTime:value());
    local MsgType = helper.parseCDATA(doc.xml.MsgType:value());

    local replyContent = ""
    if MsgType == "event" then
        replyContent = self:handleEvent(doc, FromUserName, ToUserName)
    else
        replyContent = self:handleInput(doc, FromUserName, ToUserName)    
    end
    
    return {FromUserName=ToUserName, ToUserName=FromUserName, time=os.time(), content=replyContent}
end

-- 处理扫码关注公众号或者扫码事件等...
function logic:handleEvent(doc, FromUserName, ToUserName)
    -- <xml><ToUserName><![CDATA[gh_734fd8309fc9]]></ToUserName>
    --     <FromUserName><![CDATA[oEBOw6h23Cwew20ntrSk4TKfbCNM]]></FromUserName>
    --     <CreateTime>1667802555</CreateTime>
    --     <MsgType><![CDATA[event]]></MsgType>
    --     <Event><![CDATA[subscribe]]></Event>
    --     <EventKey><![CDATA[]]></EventKey>
    -- </xml>
    local replyContent = "欢迎关注Nobook, 精彩一触即发~"
    local event = helper.parseCDATA(doc.xml.Event:value());
    if event == "subscribe" then
        -- 关注事件
        local scene = helper.parseCDATA(doc.xml.EventKey:value());
        scene = "qrscene_NHAK5ElJqz73YHaYhltG"
        if scene and helper.starts(scene, "qrscene_") then
            -- 扫码场景值二维码进行关注
            scene = string.gsub(scene, "qrscene_", "")
            self:login(FromUserName, scene)
        end
    elseif event == "SCAN" then
        -- 扫码事件
        local scene = helper.parseCDATA(doc.xml.EventKey:value());
        self:login(FromUserName, scene)
    elseif event == "unsubscribe" then
        -- 取消订阅
        -- replyContent = "取消订阅成功, Nobook期待与你再相聚~~~"
        replyContent = ""
    elseif event == "CLICK" then
        -- 自定义菜单点击
        replyContent = ""
    else
        replyContent = ""
    end

    return replyContent
end

-- 执行登录逻辑
function logic:login(FromUserName, scene)
    local red = redis.new()
    red:exec(function(red)
        return red:setex("wechat:login_key:" .. scene, 600, FromUserName)
    end)
end

-- 处理公众号输入事件
function logic:handleInput(doc, FromUserName, ToUserName, MsgType)
    -- <xml><ToUserName><![CDATA[gh_734fd8309fc9]]></ToUserName>
    --     <FromUserName><![CDATA[oEBOw6h23Cwew20ntrSk4TKfbCNM]]></FromUserName>
    --     <CreateTime>1667389310</CreateTime>
    --     <MsgType><![CDATA[text]]></MsgType>
    --     <Content><![CDATA[2fff]]></Content>
    --     <MsgId>23871275387728177</MsgId>
    -- </xml>
    return ""
    -- local replyContent = "欢迎关注Nobook, 精彩一触即发~"
    -- if MsgType == "text" then
    --     local content = helper.parseCDATA(doc.xml.Content:value());
    -- end
    -- self:sendWelcomeMessage(FromUserName, "hello~~~")
    -- return replyContent
end

function logic:sendWelcomeMessage(FromUserName, content)
    wechatUtil.sendMessage({
        touser = FromUserName,
        msgtype = "text",
        text = {
            content = content,
        }
    })
end


function logic:getTicket()
    return wechatUtil.getTicket()
end

function logic:checkLogin(scene)
    local red = redis.new()
    local openId, err = red:exec(function(red)
        -- red:incrby("wechat:login_key:a" .. scene, 1)
        return red:get("wechat:login_key:" .. scene)
    end)

    -- print(openId, type(openId), err, type(err))
    -- openId 不存在时是UserData类型
    if not openId or openId == ngx.null then
        return "no"
    end
    return "yes"
end

return logic
