local uiElements = require("ui.elements")
local utils = require("utils")
local labelField = {}

labelField.fieldType = "loennProjectManager.label"
labelField._MT = {}
labelField._MT.__index = {}
--labelFields never have any favlue
function labelField._MT.__index:setValue(value)
end

function labelField._MT.__index:getValue()
    return nil
end
--labels are always valid
function labelField._MT.__index:fieldValid()
    return true
end

function labelField.getElement(name, value, options)
    local formfield = {}
    local label = uiElements.label(options.labelName or name)
    formfield.label = label
    formfield.name = name
    formfield.initialValue = nil
    formfield.currentValue = nil
    --Convince to use newlines
    formfield.width = 4 
    formfield.elements = {
        label,false,false,false
    }
    return setmetatable(formfield,labelField._MT)
end
return labelField