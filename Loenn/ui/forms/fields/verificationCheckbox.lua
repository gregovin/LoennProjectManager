local uiElements = require("ui.elements")
local verificationCheckbox = {}
verificationCheckbox.fieldType = "loennProjectManager.verificationCheckbox"

verificationCheckbox._MT = {}
verificationCheckbox._MT.__index = {}
local invalidStyle = {
    normalBorder = { 0.65, 0.2, 0.2, 0.9, 2.0 },
    focusedBorder = { 0.9, 0.2, 0.2, 1.0, 2.0 }
}
function verificationCheckbox._MT.__index:setValue(value)
    self.currentValue = value
end

function verificationCheckbox._MT.__index:getValue()
    return self.currentValue
end

function verificationCheckbox._MT.__index:fieldValid()
    return type(self:getValue()) == "boolean" and self:getValue()
end

local function updateFieldStyle(formField, wasValid, valid)
    if wasValid ~= valid then
        if valid then
            -- Reset to default
            formField.checkbox.style = nil
        else
            formField.checkbox.style = invalidStyle
        end

        formField.checkbox:repaint()
    end
end

local function fieldChanged(formField)
    return function(element, new, old)
        local wasValid = formField:fieldValid()

        formField.currentValue = new

        local valid = formField:fieldValid()

        updateFieldStyle(formField, wasValid, valid)
        formField:notifyFieldChanged()
    end
end

function verificationCheckbox.getElement(name, value, options)
    local formField = {}

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local checkbox = uiElements.checkbox(options.labelName or name, false, fieldChanged(formField))
    local element = checkbox

    if options.tooltipText then
        checkbox.interactive = 1
        checkbox.tooltipText = options.tooltipText
    end

    checkbox.centerVertically = true

    formField.checkbox = checkbox
    formField.name = name
    formField.initialValue = false
    formField.currentValue = false
    formField.sortingPriority = 10
    formField.width = 1
    formField.elements = {
        checkbox
    }

    return setmetatable(formField, verificationCheckbox._MT)
end

return verificationCheckbox
