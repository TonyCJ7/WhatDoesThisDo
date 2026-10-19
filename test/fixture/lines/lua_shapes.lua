local LuaConfig = {}

print(LuaConfig.run())

function LuaConfig.run()
  return LUA_LIMIT + LuaConfig.luaAttempt(1)
end

LUA_LIMIT = 3

function LuaConfig.luaAttempt(n)
  return n
end
