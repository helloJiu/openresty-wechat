-- 业务路由管理
local wechatRouter = require("app.routes.wechat")
local log = require("lapis.logging")
local cjson = require("cjson")

return function(app)
    -- 微信相关路由
    wechatRouter(app)

    app:post("/post", function(self)
        local body = cjson.decode(self.req.read_body_as_string())
        return { json = body}
    end)
    -- simple router: render html, visit "/" or "/?name=foo&desc=bar
    -- app:get(
    --     "/test",
    --     function(self)
    --         -- local data = {
    --         --     name = self.param.name or "lor",
    --         --     desc = self.param.desc or "a framework of lua based on OpenResty"
    --         -- }
    --         log.notice(log.flatten_params(self.req.params_get))
    --         log.notice("++++++++++++++++++userRouter")
    --         log.query(self.req.params_get)
    --         log.request(self)
    --         return { render = "index" }
    --     end
    -- )
end
