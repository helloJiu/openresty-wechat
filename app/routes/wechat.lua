-- 微信事件相关路由
local wechatLogic = require("app.logic.wechatLogic"):New()
local log = require("lapis.logging")
local helper = require("app.lib.helper")
local wechatUtil = require("app.lib.wechatUtil")
local wechatVerifyToken = require("app.config.config").wechat.verifyToken

return function(app)
    -- 验证微信Token
    -- https://developers.weixin.qq.com/doc/offiaccount/Basic_Information/Access_Overview.html#
    app:get(
        "/wechat/accept",
        function(self)
            self.res.headers["Content-Type"] = "text/plain"
            local checkStatus = wechatUtil.checkSignature(
                self.req.params_get.signature, self.req.params_get.timestamp,
                self.req.params_get.nonce, wechatVerifyToken
            )
            if checkStatus == false then
                ngx.say("sign error")
            end
            ngx.say(self.req.params_get.echostr)
            return {skip_render=true}
        end
    )

    -- 接收微信消息和事件
    -- https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Receiving_standard_messages.html
    -- https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Receiving_event_pushes.html
    app:post(
        "/wechat/accept",
        function(self)
            local checkStatus = wechatUtil.checkSignature(
                self.req.params_get.signature, self.req.params_get.timestamp,
                self.req.params_get.nonce, wechatVerifyToken
            )
            if checkStatus == false then
                ngx.say("sign error")
                return {skip_render=true}
            end

            local data = wechatLogic:acceptMessage(self.req.read_body_as_string())
            if data.content == "" then
                ngx.say("success")
                return {skip_render=true}
            end
            local text = [[
                <xml>
                <ToUserName><![CDATA[%s%s></ToUserName>
                <FromUserName><![CDATA[%s%s></FromUserName>
                <CreateTime>%s</CreateTime>
                <MsgType><![CDATA[text%s></MsgType>
                <Content><![CDATA[%s%s></Content>
                <FuncFlag>0</FuncFlag>
            </xml>
            ]]
            text = string.format(text, data.ToUserName, "]]", data.FromUserName, "]]",data.time,"]]", data.content, "]]")
            self.res.headers["Content-Type"] = "application/xml"
            ngx.say(text)
            return {skip_render=true}           
        end
    )

    -- 获取带场景值二维码ticket信息
    app:get(
        "/wechat/getTicket",
        function(self)
            local ticketData = wechatLogic:getTicket()
            if ticketData == nil then
                return { json = helper.fail("获取ticket失败~", 500)}
            end
            return { json = helper.success(ticketData)}
        end
    )

    -- 校验该场景值是否已经关注或者已经扫码
    app:get(
        "/wechat/checkLogin",
        function(self)
            local scene = self.req.params_get.scene
            if scene == nil or scene == "" then
                return { json = helper.fail("参数错误~", 400)}
            end

            local status = wechatLogic:checkLogin(scene)
            return { json = helper.success(status)}
        end
    )
end
