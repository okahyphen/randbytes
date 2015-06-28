-- randbytes.lua
-- Colin 'Oka' Hall-Coates
-- MIT, 2015

local defaults = setmetatable ({
  bytes = 4,
  mask = 256,
  file = 'urandom'
}, { __newindex = function () return false end })

local files = {
  urandom = false,
  random = false
}

function files:open ()
  self.urandom = assert (io.open ('/dev/urandom', 'rb'))
  self.random = assert (io.open ('/dev/random', 'rb'))
end

function files:close (...)
  for _, f in next, {...} do
    if self[f] then
      self[f] = not assert (self[f]:close ())
    end
  end
end

local randbytes = {
  r = function (f, b)
    if f then
      return f:read (b or defaults.bytes)
    end
  end,
  generate = function (f, ...)
    if f then
      local n, m = 0, select (2, ...) or defaults.mask
      local s = f:read (select (1, ...) or defaults.bytes)

      for i = 1, s:len () do
        n = m * n + s:byte (i)
      end

      return n
    end
  end
}

function randbytes:open ()
  files:open ()

  return self
end

function randbytes:close ()
  files:close('random', 'urandom')

  return self
end

function randbytes:uread (b)
  return self.r (files.urandom, b)
end

function randbytes:read (b)
  return self.r (files.random, b)
end

function randbytes:urandom (...)
  return self.generate (files.urandom, ...)
end

function randbytes:random (...)
  return self.generate (files.random, ...)
end

function randbytes:setdefault (k, v)
  defaults[k] = v or defaults[k]
  return defaults[k]
end

randbytes:open ()

return setmetatable(randbytes, {
  __call = function (t, ...)
    return t.r (files[defaults.file], ...)
  end,
  __metatable = false,
  __newindex = function () return false end
})
