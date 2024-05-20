local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")
local contextMenu = require("ui.context_menu")
local fieldDropdown = require("ui.widgets.field_dropdown")
local configs = require("configs")
local grid = require("ui.widgets.grid")
local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")

local utils = require("utils")

local positionField = {}

positionField.fieldType = "loennProjectManager.position3d"

positionField._MT = {}
positionField._MT.__index = {}

local invalidStyle = {
    normalBorder = { 0.65, 0.2, 0.2, 0.9, 2.0 },
    focusedBorder = { 0.9, 0.2, 0.2, 1.0, 2.0 }
}

function positionField._MT.__index:setValue(value)
    self.currentTexts = {
        tostring(value[1]), tostring(value[2]), tostring(value[3])
    }
    self.posX:setText(self.currentTexts[1])
    self.posY:setText(self.currentTexts[2])
    self.posZ:setText(self.currentTexts[3])
    self.currentText = pUtils.listToString(self.currentTexts, ", ")
    self.field:setText(self.currentText)
    self.currentValue = value
end

function positionField._MT.__index:getValue()
    return self.currentValue
end

-- Use currentText field if possible, needed to "delay" the value for fieldValid
function positionField._MT.__index:getCurrentText()
    return self.currentText or self.field.text or ""
end

function positionField._MT.__index:fieldValid()
    local v = self:fieldsValid()
    return v[1] and v[2] and v[3]
end

function positionField._MT.__index:validateIdx(v)
    return type(v) == "number" and v >= self.minValue and v <= self.maxValue
end

function positionField._MT.__index:fieldsValid()
    return { self:validateIdx(self:getValue()[1]), self:validateIdx(self:getValue()[2]), self:validateIdx(self:getValue()
    [3]) }
end

local function shouldShowMenu(element, x, y, button)
    local menuButton = configs.editor.contextMenuButton
    local actionButton = configs.editor.toolActionButton

    if button == menuButton or button == actionButton then
        return true
    end

    -- elseif button == actionButton then
    --     local drawX, drawY, width, height = getFieldPreviewArea(element)

    --     return utils.aabbCheckInline(x, y, 1, 1, drawX, drawY, width, height)
    -- end
    return false
end
local function updateFieldStyle(formField, valid)
    -- Make sure the textbox visual style matches the input validity
    local validVisuals = formField.validVisuals
    if validVisuals[1] ~= valid[1] then
        if not valid[1] then
            formField.posX.style = invalidStyle
        else
            formField.posX.style = nil
        end

        formField.validVisuals[1] = valid[1]

        formField.posX:repaint()
    end
    if validVisuals[2] ~= valid[2] then
        if not valid[2] then
            formField.posY.style = invalidStyle
        else
            formField.posY.style = nil
        end

        formField.validVisuals[2] = valid[2]
        formField.posY:repaint()
    end
    if validVisuals[3] ~= valid[3] then
        if not valid[3] then
            formField.posZ.style = invalidStyle
        else
            formField.posZ.style = nil
        end
        formField.validVisuals[3] = valid[3]
        formField.posZ:repaint()
    end
end

local function fieldChanged(formField, col)
    return function(element, new, old)
        formField.currentValue[col] = #new > 0 and tonumber(new)

        formField.field:setText(pUtils.listToString(formField.currentValue, ", "))
        local valid = formField:fieldsValid()
        updateFieldStyle(formField, valid)
        formField:notifyFieldChanged()
    end
end
local function overUpdateFieldStyle(formField, valid)
    local validVisuals = formField.overValidVisuals
    if validVisuals ~= valid then
        if not valid then
            formField.field.style = invalidStyle
        else
            formField.field.style = nil
        end
        formField.overValidVisuals = valid
        formField.field:repaint()
    end
end
local function overFieldChanged(formField)
    return function(element, new, old)
        local valid = formField:fieldValid()
        overUpdateFieldStyle(formField, valid)
        formField:notifyFieldChanged()
    end
end
function positionField.getElement(name, value, options)
    local formField = {}

    local valueTransformer = options.valueTransformer or function(v)
        return v
    end

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    local nMinWidth = options.nMinWidth or options.nWidth or 80
    local nMaxWidth = options.nMaxWidth or options.nWidth or 80
    formField.minValue = options.minValue or -math.huge
    formField.maxValue = options.maxValue or math.huge
    local editable = options.editable

    local label = uiElements.label(options.displayName or name)
    local field = uiElements.field(pUtils.listToString(value, ", "), overFieldChanged(formField)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local posX = uiElements.field(tostring(value[1]), fieldChanged(formField, 1)):with({
        minWidth = nMinWidth,
        maxWidth = nMaxWidth
    })
    local posY = uiElements.field(tostring(value[2]), fieldChanged(formField, 2)):with({
        minWidth = nMinWidth,
        maxWidth = nMaxWidth
    })
    local posZ = uiElements.field(tostring(value[3]), fieldChanged(formField, 3)):with({
        minWidth = nMinWidth,
        maxWidth = nMaxWidth
    })

    if editable == false then
        posX:setEnabled(false)
        posY:setEnabled(false)
        posZ:setEnabled(false)
    end

    posX:setPlaceholder(tostring(value[1] or 0))
    posY:setPlaceholder(tostring(value[2] or 0))
    posZ:setPlaceholder(tostring(value[3] or 0))
    local x = uiElements.label("x")
    local y = uiElements.label("y")
    local z = uiElements.label("z")
    local fieldContext = contextMenu.addContextMenu(
        field,
        function()
            return grid.getGrid({
                x, y, z,
                posX, posY, posZ
            }, 3)
        end,
        {
            shouldShowMenu = shouldShowMenu,
            mode = "focused"
        }
    )
    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.posX = posX
    formField.posY = posY
    formField.posZ = posZ
    formField.field = field
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.valueTransformer = valueTransformer
    formField.validVisuals = { true, true, true }
    formField.overValidVisuals = true
    formField.width = 2
    formField.elements = {
        label, fieldContext
    }

    formField = setmetatable(formField, positionField._MT)

    return formField
end

return positionField
