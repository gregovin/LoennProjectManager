local uiElements = require("ui.elements")
local filesystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local iconUtils = require("ui.utils.icons")
local uiUtils = require("ui.utils")
local utils = require("utils")
local nullableFilepathField = {}

nullableFilepathField.fieldType = "loennProjectManager.nullableFilePath"

nullableFilepathField._MT = {}
nullableFilepathField._MT.__index = {}

function nullableFilepathField._MT.__index:setValue(value)
    self.currentValue = value
end

function nullableFilepathField._MT.__index:getValue()
    return self.currentValue
end

function nullableFilepathField._MT.__index:fieldValid()
    local value = self:getValue()
    return type(value) == "string" and
        (filesystem.isFile(value) or filesystem.isDirectory(value) or (value == "" and self.allowEmpty))
end

local function updateButtonLabel(button, newFilepath)
    if newFilepath then
        button.label.text = utils.filename(utils.stripExtension(newFilepath):gsub("\\", "/"), "/") or ""
        button.label.interactive = 1
        button.label.tooltipText = newFilepath
    else
        button.label.text = ""
    end
end

local function createSelectFileCallback(self, button)
    return function(filepath)
        updateButtonLabel(button, filepath)
        self.currentValue = filepath
        self:notifyFieldChanged()
    end
end

local function buttonPressed(self, options)
    local location = (self.currentValue and filesystem.dirname(self.currentValue)) or options.location
    if options.requireDir then
        return function(button)
            filesystem.openFolderDialog(location, createSelectFileCallback(self, button))
        end
    else
        return function(button)
            filesystem.openDialog(location, options.extension, createSelectFileCallback(self, button))
        end
    end
end

function nullableFilepathField.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    options.extension = options.extension or "bin"
    formField.initialValue = value
    formField.currentValue = value
    options.location = options.location or fileLocations.getCelesteDir()
    local label = uiElements.label(options.displayName or name)
    local button
    if options.enabled == false then
        button = uiElements.button("", function() end):with({
            minWidth = minWidth,
            maxWidth = maxWidth
        })
    else
        button = uiElements.button("",
            buttonPressed(formField, options)):with({
            minWidth = minWidth,
            maxWidth = maxWidth
        })
    end
    updateButtonLabel(button, value)
    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true
    local clearinator = uiElements.button("X", function()
        formField:setValue("")
        updateButtonLabel(button, "")
    end)

    formField.label = label
    formField.button = button
    formField.name = name
    formField.width = 2
    formField.allowEmpty = options.allowEmpty

    formField.elements = {
        label, button, clearinator
    }
    setmetatable(formField, nullableFilepathField._MT)

    return formField
end

return nullableFilepathField
