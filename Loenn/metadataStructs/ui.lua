local uiStruct = {}

---Decode a ui struct
---@param data table?
---@return table
function uiStruct.decode(data)
    local res = {
        _type = "ui"
    }
    for k, v in pairs(data or {}) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end
    return res
end

---Encode a ui struct
---@param ui table
function uiStruct.encode(ui)
    local res = {}
    for k, v in pairs(ui) do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end
    res.__name = "ui"

    return res
end

return uiStruct
