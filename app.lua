local lapis = require("lapis")
local app = lapis.Application()
local router = require("app.router")
-- app:enable("etlua")

app:get("/", function()
  return "Welcome to Lapis " .. require("lapis.version")
end)

router(app)

return app
