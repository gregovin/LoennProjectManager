
local utils = require("utils")
local cachelib = {val ={}, arena = {}}

cachelib.val._MT={__index={}}

---Resets the cached value
function cachelib.val._MT.__index:reset()
    self._val=nil
end
---Get the underlying cached value, computing it if needed
---@param i table
---@return any
function cachelib.val._MT.__call(i)
    if i._val==nil then
        i._val = utils.callIfFunction(i._init)
    end
    return i._val
end
---Get a cached value. A cahced value will run the init function and return the result the first time it is called, on subsequent calls it will return a cahced value until it is reset.
---ie  `local cv = cachelib.getCacheVal(function (v) return do_expensive_thing end); print(cv()) --expensive thing is done; print(cv()) --uses cached value`
---@param init any
---@return table cacheVal
function cachelib.getCacheVal(init)
    local v = {_init = init}
    return setmetatable(v, cachelib.val)
end
cachelib.arena._MT={__index={}}
---Initialize a cached arena value
---@param key any the key to use
---@param init any how to initialize the value. If a function will be called with zero args the first time the key is accessed
function cachelib.arena._MT.__index:initCached(key, init)
    self._inits[key] = init
    self._is_set[key] = false
end
---Reset every key in the arena
function cachelib.arena._MT.__index:reset()
    self._vals ={}
    self._is_set={}
end
---read out the cached value, initializing it if needed
---@param key any
---@return any
function cachelib.arena._MT.__index:get(key)
    if not self._is_set[key] then
        self._vals[key] = utils.callIfFunction(self._inits)
        self._is_set[key]=true
    end
    return self._vals[key]
end
---Return a cache arena. A cache arena has the property where each key is initialized individually, but all keys in the arena are reset by the same `reset` call
---@return table arena
function cachelib.getCacheArena()
    return setmetatable({_inits={},_vals={},_is_set={}}, cachelib.arena)
end
return cachelib