local unusedStruct = {}

---Decode a unused struct
---@param data table?
---@return table
function unusedStruct.decode(data)
    local res = {
        _type = "unused"
    }
    for k, v in pairs(data or {}) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end
    res.file = res.file or ""
    return res
end

---Encode a unused struct
---@param unused table
function unusedStruct.encode(unused)
    local res = {}
    for k, v in pairs(unused) do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end
    res.__name = "unused"

    return res
end

return unusedStruct
