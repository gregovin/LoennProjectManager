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
        fieldType = "loennProjectManager.filePath"
    }

}
function unused.displayName(language, item)
    return fileSystem.stripExtension(fileSystem.fileName(item.file))
end

function unused.filename(item)
    return item.file
end

function unused.fieldOrder(item)
    return fieldOrder
end

function unused.fieldInformation(item)
    return fieldInformation
end

function unused.defaultData(item)
    return defaultData
end

return unused
