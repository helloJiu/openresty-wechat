# Openresty Wechat

使用Nginx-LuaJit-OpenResty-Lapis技术栈搭建的专用于处理微信公众号回调服务的项目

## 项目源码
https://github.com/helloJiu/openresty-wechat
## 微信公众平台测试号申请
https://mp.weixin.qq.com/debug/cgi-bin/sandboxinfo?action=showinfo&t=sandbox/index
## 内网穿透工具
https://www.cpolar.com/
```
cpolar.exe http 8123
```
## openresty源码安装(ubuntu为例)
```
apt install gcc libpcre3-dev libssl-dev perl make build-essential
wget https://openresty.org/download/openresty-1.19.9.1.tar.gz
tar -zxvf openresty-1.19.9.1.tar.gz
cd openresty-1.19.9.1/
./configure
make && make install
```

## 配置环境变量
```
vim /etc/profile
export PATH=$PATH:/usr/local/openresty/bin:/usr/local/openresty/luajit/bin
source /etc/profile

# 设置lua软链到luajit
ln -s  /usr/local/openresty/luajit/bin/luajit lua
mv lua /usr/bin/
```

## 安装lapis
- https://leafo.net/lapis/

```
luarocks install lapis
```

## 安装redis依赖包和http-client依赖包以及其他依赖
```
opm install lua-resty-string
opm install openresty/lua-resty-redis
opm install ledgetech/lua-resty-http
```
## 配置app/config/config.lua
```lua
	-- 微信相关配置
	wechat = {
		appId = "",  --公众号id
		appSecret = "", -- 公众号秘钥
		verifyToken = "", -- 公众号token
	},
	-- redis相关配置
	redis = {
		host = "127.0.0.1",
		port = 6379,
		password = "",
		db_index = 0,
		max_idle_time = 30000,
		database = 0,
		pool_size = 100,
		timeout = 5000,
	},
```
## 启动项目
```
lapis server
```

## 压力测试

```
## autocannon压测命令需要使用npm安装
autocannon -c 100 -d 30 -p 2 -t 2 http://127.0.0.1:8123/wechat/checkLogin?scene=NHAK5ElJqz73YHaYhltG

## 运行结果
Running 30s test @ http://10.254.39.195:8123/wechat/checkLogin?scene=NHAK5ElJqz73YHaYhltG
100 connections with 2 pipelining factor


┌─────────┬───────┬────────┬────────┬────────┬───────────┬───────────┬─────────┐
│ Stat    │ 2.5%  │ 50%    │ 97.5%  │ 99%    │ Avg       │ Stdev     │ Max     │
├─────────┼───────┼────────┼────────┼────────┼───────────┼───────────┼─────────┤
│ Latency │ 12 ms │ 314 ms │ 652 ms │ 701 ms │ 316.26 ms │ 186.86 ms │ 3094 ms │
└─────────┴───────┴────────┴────────┴────────┴───────────┴───────────┴─────────┘
┌───────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ Stat      │ 1%      │ 2.5%    │ 50%     │ 97.5%   │ Avg     │ Stdev   │ Min     │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Req/Sec   │ 7259    │ 7259    │ 8807    │ 9207    │ 8714.94 │ 436.3   │ 7258    │
├───────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ Bytes/Sec │ 1.58 MB │ 1.58 MB │ 1.92 MB │ 2.01 MB │ 1.9 MB  │ 95.1 kB │ 1.58 MB │
└───────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘

Req/Bytes counts sampled once per second.
# of samples: 30

267k requests in 30.03s, 57 MB read
55 errors (0 timeouts)

## QPS大概8700+
```

