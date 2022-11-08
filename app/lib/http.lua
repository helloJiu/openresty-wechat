-- http客户端
-- https://github.com/ledgetech/lua-resty-http
local http = require("resty/http")
local config = require("app.config.config").http

local _M = {}

function _M.new()
    local instance = {
        timeout = config.timeout or 5000,
        max_idle_time = config.max_idle_time or 60000,
        pool_size = config.pool_size or 1000,
        backlog = config.backlog or 1000,
    }
    setmetatable(instance, { __index = _M })
    return instance
end


function _M:exec(options, func)
    local httpc = http:new()
    -- Sets the socket timeout (in ms) for subsequent operations. 
    httpc:set_timeout(self.timeout)

    -- https://github.com/openresty/lua-nginx-module#tcpsockconnect
    -- pool_size 指定连接池的大小。
    -- 如果省略且未 backlog提供任何选项，则不会创建任何池。如果省略但backlog已提供，
    -- 则将使用等于lua_socket_pool_size 指令的值的默认大小创建池。
    -- 连接池可容纳可供pool_size后续调用connect重用的活动连接，
    -- 但请注意，池外打开的连接总数没有上限。如果您需要限制打开的连接总数，
    -- 请指定backlog选项。当连接池超过其大小限制时，
    -- 池中最近最少使用（保持活动）的连接将被关闭，以为当前连接腾出空间。请注意，
    -- cosocket 连接池是每个 Nginx 工作进程而不是每个 Nginx 服务器实例，
    -- 因此此处指定的大小限制也适用于每个 Nginx 工作进程。
    -- 另请注意，连接池的大小一旦创建就无法更改。此选项首次在v0.10.14发行版中引入。
    options.pool_size = self.pool_size

    -- backlog 如果指定，此模块将限制此池的打开连接总数。
    -- pool_size任何时候都不能为此池打开更多的连接。
    -- 如果连接池已满，后续连接操作将排入与此选项值相等的队列（积压队列）。
    -- 如果排队的连接操作数等于backlog，后续连接操作将失败并返回nil错误字符串"too many waiting connect operations"。
    -- 一旦池中的连接数小于 ，排队的连接操作将恢复pool_size。
    -- 排队的连接操作将在排队超过 时中止connect_timeout，由 settimeouts控制，并返回nil错误字符串。
    -- "timeout". 此选项首次在v0.10.14发行版中引入。
    options.backlog = self.backlog
    options.ssl_verify = false
    local ok, err = httpc:connect(options)
    if not ok then
        ngx.log(ngx.ERR, "http connect, err:", err)
        return nil, err
    end

    -- 执行业务逻辑
    local res, err = func(httpc)
    if not res then 
        ngx.log(ngx.ERR, "http request, err:", err)
        return nil, err
    end
    -- 读取响应体
    local res_body = ""
    if res.status == 200 and res.has_body then
        local reader = res.body_reader
        local buffer_size = 4096
        repeat
            local buffer, err = reader(buffer_size)
            if err then 
                ngx.log(ngx.ERR, "reader err", err)
                break
            end

            if buffer then
                res_body = res_body .. buffer
            end
        until not buffer
    end

    -- 将连接放回连接池
    local ok = httpc:set_keepalive(self.max_idle_time, self.pool_size)
    if not ok then
        httpc:close()
    end
    -- 返回响应体  响应  以及err
    return res_body, res, err
end



return _M