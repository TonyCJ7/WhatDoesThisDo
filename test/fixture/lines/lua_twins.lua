local LuaTwins = {}

print(luaTwin(1), LuaTwins.luaTwin(1, 2))

local function luaTwin(n)
  return n
end

function LuaTwins.luaTwin(n, m)
  return n + m
end
