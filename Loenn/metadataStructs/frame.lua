local frameStruct = {}

---Decode a frame struct
---@param data table?
---@return table
function frameStruct.decode(data)
    local res = {
        _type = "frame"
    }
    for k, v in pairs(data or {}) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end
    return res
end

---Encode a frame struct
---@param frame table
function frameStruct.encode(frame)
    local res = {}
    for k, v in pairs(frame) do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end
    res.__name = "frame"

    return res
end


return frameStruct
