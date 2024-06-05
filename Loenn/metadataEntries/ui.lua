local ui = {}

local defaultData = {
}
local fieldOrder = {
}
local fieldInformation = {}
function ui.displayName(language, item)
    return "Title"
end

function ui.defaultData(item)
    return defaultData
end

function ui.fieldOrder(item)
    return fieldOrder
end

function ui.fieldInformation(item)
    return fieldInformation
end

return ui
