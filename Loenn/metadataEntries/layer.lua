local layer = {}

local defaultData = {
    x = 0.0,
    y = 0.0,
    scrollX = 0.0,
    scrollY = 0.0,
    frameRate = 4,
    loop = false,
    scale = 1.0,
    speedX = 0.0,
    speedY = 0.0,
    alpha = 1.0
}
local fieldOrder = {
    "x", "y", "scrollX", "speedX", "speedY", "scrollY", "frameRate", "loop", "scale", "alpha"
}
local fieldInformation = {
    frameRate = {
        fieldType = "integer",
        minimumValue = 1
    },
    loop = {
        fieldType = "boolean",
        tooltipText = "Weather or not the animation loops"
    },
    scale = {
        fieldType = "number",
        minimumValue = 0.0
    },
    alpha = {
        fieldType = "number",
        minimumValue = 0.0,
        maximumValue = 1.0
    }
}

function layer.fieldOrder(item)
    return fieldOrder
end

function layer.fieldInformation(item)
    return fieldInformation
end

---Get the default data for this form
---@param item Item
---@return table
function layer.defaultData(item)
    return defaultData
end

function layer.displayName(language, item)
    return "Layer"
end

return layer
