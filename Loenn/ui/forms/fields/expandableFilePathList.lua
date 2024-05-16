local uiElements = require("ui.elements")
local filesystem = require("utils.filesystem")

local contextMenu = require("ui.context_menu")
local fileLocations = require("file_locations")
local mods = require("mods")
local expandableGrid = mods.requireFromPlugin("ui.widgets.expandableGrid")
local utils = require("utils")
local directFilepathList = {}

directFilepathList.fieldType = "loennProjectManager.filePathList"

directFilepathList._MT = {}
directFilepathList._MT.__index = {}

function directFilepathList._MT.__index:setValue(value)
    self.currentValue = value
end

function directFilepathList._MT.__index:getValue()
    return self.currentValue
end
function directFilepathList._MT.__index:validatePath(v)
    return type(v) == "string" and (filesystem.isFile(v) or filesystem.isDirectory(v) or (v=="" and self.allowEmpty))
end
function directFilepathList._MT.__index:fieldValid()
    for i,v in ipairs(self:getValue()) do
        if not self:validatePath(v) then
            return false
        end
    end
    return true
end

local function updateButtonLabel(button, newFilepath)
    if newFilepath then
        button.label.text = utils.filename(utils.stripExtension(newFilepath):gsub("\\", "/"), "/")
        button.label.interactive = 1
        button.label.tooltipText = newFilepath
    end
end
local function getLabelString(names,maxLen)
    local sep = ""
    local out = ""
    for i,v in ipairs(names) do
        out = out .. sep .. (utils.filename(utils.stripExtension(v or "")) or "")
        sep = ", "
        if i == maxLen then
            local rem = #names - maxLen
            if rem> 0 then
                out = out .. sep .. string.format("... %s more",rem)
            end
            return out
        end
    end
    return out
end
local function createSelectFileCallback(self, button, idx)
    return function(filepath)
        updateButtonLabel(button, filepath)
        self.currentValue[idx] = filepath or ""
        self.button.label.text = getLabelString(self.currentValue,self.maxLen)
        self:notifyFieldChanged()
    end
end

local function buttonPressed(self, extension, location,requireDir, idx)
    location=location or fileLocations.getCelesteDir()
    if requireDir then
        return function(button)
            filesystem.openFolderDialog(location,createSelectFileCallback(self, button, idx))
        end
    else
        return function(button)
            filesystem.openDialog(location, extension, createSelectFileCallback(self, button, idx))
        end
    end
end

function directFilepathList.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    local innerMaxWidth = options.innerMaxWidth or options.innerWidth or 160
    local innerMinWidth = options.innerMinWidth or options.innerWidth or 160
    formField.allowEmpty = options.allowEmpty
    local maxLen = options.maxLen or 1
    local label = uiElements.label(options.displayName or name)
    local button = uiElements.button(getLabelString(value,maxLen),function () end):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    formField.files = {}
    for i,v in ipairs(value) do
        local innerButton = uiElements.button((utils.filename(utils.stripExtension(v) or "") or ""),buttonPressed(formField, options.extension or "bin",options.location,options.requireDir,i)):with({
            minWidth = innerMinWidth,
            maxWidth = innerMaxWidth
        })
        formField.files[i] = innerButton
    end
    local buttonContext =  contextMenu.addContextMenu(button,function ()
        return expandableGrid.getGrid(formField.files,3,{minWidth=((innerMinWidth-25)/2),maxWidth=((innerMaxWidth-25)/2)},
            function ()
                table.insert(value,"")

                local innerButton = uiElements.button("",buttonPressed(formField,options.extension or "bin",options.location,options.requireDir,#value)):with({
                    minWidth = innerMinWidth,
                    maxWidth = innerMaxWidth
                })
                table.insert(formField.files, innerButton)
                formField.button.label.text = getLabelString(value,maxLen)
                return innerButton
            end,
            function (idx)
                table.remove(value)
                table.remove(formField.files)
                formField.button.label.text = getLabelString(value,maxLen)
            end
        )
    
    end,{
        shouldShowMenu = function () return true end,
        mode = "focused"
    })

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.button = button
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.maxLen = maxLen
    formField.width = 2
    formField.elements = {
        label, buttonContext
    }

    return setmetatable(formField, directFilepathList._MT)
end

return directFilepathList