local mods = require('mods')
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

---@class Handler
local frame = {}

local fieldOrder = {
    "texture"
}
local defaultData = {
    texture = ""
}
local fieldInformation = {
    texture = {
        options = {},
        editable = false
    }
}
---Get a list of all image names
---@return string[]
function frame.getImageNames(files)
    local res = {}
    for i, v in ipairs(files) do
        table.insert(res, { fileSystem.filename(fileSystem.stripExtension(v or "") or "") or "", v })
    end
    fieldInformation.texture.options = res
    return res
end

---Get the display name for the item
---@param language any the language object
---@param item table the item to get
---@return string
function frame.displayName(language, item)
    return string.format("Frame - %s", item.texture)
end

---Get the default data for this form
---@param item Item
---@return table
function frame.defaultData(item)
    return defaultData
end

function frame.fieldOrder(item)
    return fieldOrder
end

function frame.fieldInformation(item)
    return fieldInformation
end

---get the filename from a frame
---@param item any
---@return string
function frame.fileName(item)
    local atlas = metadataHandler.getNestedValue({ "CompleteScreen", "Atlas" })
    local details = pUtils.getProjectDetails()
    return fileSystem.joinpath(modsDir, details.name, "Graphics", "Atlases", atlas, item.texture .. ".png")
end

return frame
