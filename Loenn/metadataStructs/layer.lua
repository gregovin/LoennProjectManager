local layerStruct = {}

---Decode a layer struct
---@param data table?
---@return table
function layerStruct.decode(data)
    local res = {
        _type = "layer"
    }
    for k, v in pairs(data or {}) do
        if not string.match(k, "^__") then
            res[k] = v
        end
    end
    return res
end

---Encode a layer struct
---@param layer table
function layerStruct.encode(layer)
    local res = {}
    for k, v in pairs(layer) do
        if k:sub(1, 1) ~= "_" then
            res[k] = v
        end
    end
    res.__name = "layer"

    return res
end

return layerStruct
