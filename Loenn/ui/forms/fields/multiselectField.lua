local uiElements = require("ui.elements")
local utils = require("utils")
local logging = require("logging")
require("mods").requireFromPlugin("ui.elements.multiselect")

local multiselectField = {}

multiselectField.fieldType = "loennProjectManager.multiselect"

multiselectField._MT = {}
multiselectField._MT.__index = {}
local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}
function multiselectField._MT.__index:setValue(value)
    self.currentValue = value
end
function multiselectField._MT.__index:setValueNames(valueNames)
    self.currentValueNames = valueNames
end
function multiselectField._MT.__index:getValue()
    return self.currentValue
end
function multiselectField._MT.__index:getValueNames()
    return self.currentValueNames
end
function multiselectField._MT.__index:fieldValid()
    local value = self:getValue()
    return type(value) == "table" and self.validator(self:getValue())
end
local function updateFieldStyle(formField, wasValid, valid)
    if wasValid ~= valid then
        if valid then
            -- Reset to default
            formField.field.style = nil

        else
            formField.field.style = invalidStyle
        end

        formField.field:repaint()
    end
end
local function prepareDropdownOptions(options)
    local flattenedOptions = {}

    if utils.isCallable(options) then
        options = options()
    end

    -- Assume this is a unordered table, manually flatten
    if #options == 0 then
        for k, v in pairs(options) do
            table.insert(flattenedOptions, {k, v})
        end

        -- Sort by name
        flattenedOptions = table.sortby(flattenedOptions, (t -> t[1]))()

    else
        -- Check if already flattened or only values
        if type(options[1]) == "table" then
            for i, option in ipairs(options) do
                flattenedOptions[i] = option

            end

        else
            for i, v in ipairs(options) do
                local name = v

                flattenedOptions[i] = {name, v}

            end
        end
    end

    return flattenedOptions
end
local function dropdownChanged(formField, optionsFlattened)
    return function(element, new)
        local values={}
        local old = formField.currentValue

        for _, option in ipairs(optionsFlattened) do
            values[option[2]]=new[option[1]]
        end

        if values ~= old then
            local wasValid = formField:fieldValid()

            formField.currentValue = values

            local valid = formField:fieldValid()

            updateFieldStyle(formField, wasValid, valid)
            formField:notifyFieldChanged()
        end
    end
end

function multiselectField.getElement(name, value, options)
    local formField = {}
    formField.value=value
    local flatOptions= prepareDropdownOptions(options.options)
    options.options=flatOptions
    local optionNames={}
    for i, option in ipairs(flatOptions) do
        optionNames[i] = option[1]
    end
    formField.getValueNames = multiselectField._MT.__index.getValueNames
    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    local validator=options.validator or function () return true end

    local label = uiElements.label(options.displayName or name)
    local button = uiElements.multiselect(optionNames, dropdownChanged(formField, flatOptions)):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local valInfo={}
    for k,v in pairs(value) do
        for i,val in ipairs(flatOptions) do
            if val[2]==k then
                valInfo[i]=v
                break
            end
        end
    end
    button:setSelectedIndicies(valInfo or {})
    button:updateText()
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
    formField.validator = validator
    formField.width = 2
    formField.elements = {
        label, button
    }

    return setmetatable(formField, multiselectField._MT)
end

return multiselectField