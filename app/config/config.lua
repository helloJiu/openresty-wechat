return {
	-- redis配置
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

	-- http client 连接池配置
	http = {
		max_idle_time = 30000,
		pool_size = 1000,
		timeout = 5000,
		backlog = 1000
	},

	-- 分页时每页条数配置
	page_config = {
	},

	-- mysql配置
	mysql = {
		timeout = 5000,
		connect_config = {
			host = "127.0.0.1",
	        port = 3306,
	        database = "openresty",
	        user = "hu",
	        password = "",
	        max_packet_size = 1024 * 1024
		},
		pool_config = {
			max_idle_timeout = 20000, -- 20s
        	pool_size = 50 -- connection pool size
		}
	},

	-- 微信相关配置
	wechat = {
		appId = "",
		appSecret = "",
		verifyToken = "",
	},
	

}
