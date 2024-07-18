local fileSystem = require("utils.filesystem")
local unused = {}

local defaultData = {
    file = ""
}
local fieldOrder = {
    "file"
}

local fieldInformation = {
    file = {
        fieldType = "loennProjectManager.filePath",
        extension = "png"
    }

}
function unused.displayName(language, item)
    return "File: " .. (fileSystem.stripExtension(fileSystem.filename(item.file) or "") or "None")
end

function unused.filename(item)
    return item.file
end

function unused.fieldOrder(item)
    return fieldOrder
end

function unused.fieldInformation(item)
    fieldInformation.file.enabled = item.claimed
    return fieldInformation
end

function unused.defaultData(item)
    return defaultData
end

function unused.processFileName(f)
    return fileSystem.filename(f) or ""
end

return unused
