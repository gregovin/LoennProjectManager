local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local fieldDropdown = require("ui.widgets.field_dropdown")

local utils = require("utils")
local logging = require('logging')

local positionField = {}

positionField.fieldType = "loennProjectManager.position3d"

positionField._MT = {}
positionField._MT.__index = {}

local warningStyle = {
    normalBorder = {0.65, 0.5, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.67, 0.2, 1.0, 2.0}
}

local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}

function positionField._MT.__index:setValue(value)
    self.currentText = {
        tostring(value[1]),tostring(value[2]),tostring(value[3])
    }
    self.posX:setText(self.currentText[1])
    self.posY:setText(self.currentText[2])
    self.posZ:setText(self.currentText[3])
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
    return {type(self:getValue()[1])=="number", type(self:getValue()[2])=="number", type(self:getValue()[3])=="number"}
end
local function updateFieldStyle(formField, valid)
    -- Make sure the textbox visual style matches the input validity
    local validVisuals = formField.validVisuals
    if validVisuals[1]~= valid[1] then
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

local function fieldChanged(formField,col)
    return function(element, new, old)
        formField.currentValue[col] = new
        
        local valid = formField:fieldValid()
        updateFieldStyle(formField, valid)
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

    local editable = options.editable

    local label = uiElements.label(options.displayName or name)
    local posX = uiElements.field(tostring(value[1]), fieldChanged(formField,1)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local posY = uiElements.field(tostring(value[2]), fieldChanged(formField,2)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local posZ = uiElements.field(tostring(value[3]),fieldChanged(formField,3)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })

    if editable == false then
        posX:setEnabled(false)
        posY:setEnabled(false)
        posZ:setEnabled(false)
    end

    posX:setPlaceholder(value[1] or 0)
    posY:setPlaceholder(value[2] or 0)
    posZ:setPlaceholder(value[3] or 0)

    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end

    label.centerVertically = true

    formField.label = label
    formField.posX = posX
    formField.posY = posY
    formField.posZ = posZ
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.valueTransformer = valueTransformer
    formField.validVisuals = {true,true,true}
    formField.width = 2
    formField.elements = {
        label, posX,posY,posZ
    }

    formField = setmetatable(formField, positionField._MT)

    return formField
end

return positionField