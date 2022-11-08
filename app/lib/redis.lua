-- redis客户端 
-- https://segmentfault.com/a/1190000007207616
-- https://github.com/openresty/lua-resty-redis
-- https://xiaorui.cc/archives/4784
-- https://cloud.tencent.com/developer/news/863285
local redis = require("resty/redis")
local config = require("app.config.config").redis

local _M = {}

function _M.new()
    local instance = {
        host = config.host or "127.0.0.1",
        port = config.port or 6379,
        password = config.password or "",
        timeout = config.timeout or 5000,
        database = config.database or 0,
        max_idle_time = config.max_idle_time or 60000,
        pool_size = config.pool_size or 100
    }
    setmetatable(instance, {__index = _M})
    return instance
end

function _M:exec(func)
    local red = redis:new()
    -- 为后续操作设置超时（以毫秒为单位）保护，包括connect方法。
    red:set_timeout(self.timeout)

    -- 建立连接
    local ok, err = red:connect(self.host, self.port)
    if not ok then
        ngx.log(ngx.ERR, "Redis: ", "Cannot connect, host: " .. self.host .. ", port: " .. self.port)
        return nil, err
    end

    if self.password ~= "" then
        -- 如果连接来自于连接池中，get_reused_times() 永远返回一个非零的值
        -- 只有新的连接才会进行授权
        local count, err = red:get_reused_times()
        if count == 0 then
            ok, err = red:auth(self.password)
            if not ok then
                red:close()
                return ok, err
            end
        end
    end

    if self.database ~= 0 then
        red:select(self.database)
    end

    -- 执行业务逻辑
    local res, err = func(red)
    -- 将连接放回连接池
    local ok, err = red:set_keepalive(self.max_idle_time, self.pool_size)
    if not ok then
        red:close()
    end
    return res, err
end

return _M