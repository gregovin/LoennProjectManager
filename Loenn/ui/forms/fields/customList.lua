local mods = require("mods")
local contextMenu = require("ui.context_menu")
local ui = require("ui")
local uiElements = require("ui.elements")
local languageRegistry = require("language_registry")
local uiUtils = require("ui.utils")
local form = require("ui.forms.form")
local logging = require("logging")

local listField = {}
listField.fieldType = "loennProjectManager.customList"

listField._MT = {}
listField._MT.__index = {}

local invalidStyle = {
    normalBorder = { 0.65, 0.2, 0.2, 0.9, 2.0 },
    focusedBorder = { 0.9, 0.2, 0.2, 1.0, 2.0 }
}

function listField._MT.__index:setValue(value)
    self.currentValue = value
end

function listField._MT.__index:getValue()
    return self.currentValue
end

function listField._MT.__index:fieldValid()
    return self.isValid
end

local function getLabelString(field, names, maxLen)
    local sep = ""
    local out = ""
    if #names == 0 then
        local count = 0
        for k, v in pairs(names) do
            if count == maxLen then
                out = out .. sep .. "..."
                return out
            end
            out = out .. sep .. field.keyDisplayTransformer(k) .. ": " .. field.displayTransformer(v)
            sep = ", "
            count += 1
        end
    else
        for i, v in ipairs(names) do
            out = out .. sep .. field.displayTransformer(v)
            sep = ", "
            if i == maxLen then
                local rem = #names - maxLen
                if rem > 0 then
                    out = out .. sep .. string.format("... %s more", rem)
                end
                return out
            end
        end
    end

    return out
end
local function valueDeleteRowHandler(formField, index)
    return function()
        local value = formField:getValue()
        local field = formField.field
        table.remove(value, index)
        field:setText(getLabelString(formField, value, formField.maxLen))
    end
end
local function valueAddRowHandler(formField)
    return function()
        local cval = formField.currentValue
        local options = formField.options
        local field = formField.field
        table.insert(cval, options.elementDefault)
        field:setText(getLabelString(formField, cval, formField.maxLen))
    end
end

local function getSubformElements(formField, value, options)
    local language = languageRegistry.getLanguage()
    local elements = {}

    for k, v in pairs(value) do
        local formElement = form.getFieldElement(formField.keyDisplayTransformer(k), v, options.elementOptions)
        -- remove the label if it appears first and this is a list
        if type(k) == "number" and formElement.elements[1] == formElement.label then
            formElement.width = 1

            table.remove(formElement.elements, 1)
        end
        table.insert(elements, formElement)
        if not options.setLength then
            -- Fake remove button as a form field
            local removeButton = uiElements.button(
                tostring(language.forms.fieldTypes.list.removeButton),
                valueDeleteRowHandler(formField, k)
            )
            local fakeElement = {
                elements = {
                    removeButton
                },
                fieldValid = function()
                    return true
                end
            }
            table.insert(elements, fakeElement)
        end
    end
    return elements
end
local function updateTextField(formField, formData, options)
    formField.field:setText(getLabelString(formField, formData, formField.maxLen))
    local valid = formField:fieldValid()
    local validVisuals = formField.validVisuals

    if valid ~= validVisuals then
        if not valid then
            formField.field.style = invalidStyle
        else
            formField.field.style = nil
        end
        formField.validVisuals = valid
        formField.field:repaint()
    end
end
function listField.getElement(name, value, options)
    local formField = {}
    options = table.shallowcopy(options)
    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160
    options.elementOptions = options.elementOptions or {}

    options.elementOptions.fieldType = options.elementOptions.fieldType or "string"
    formField.allowEmpty = options.allowEmpty
    options.setLength = options.setLength or #value == 0
    formField.keyDisplayTransformer = options.keyDisplayTransformer or function(k) return tostring(k) end
    formField.displayTransformer = options.displayTransformer or function(v)
        return tostring(v)
    end
    formField.validator = options.elementOptions.validator or function(v) return true end
    formField.maxLen = options.maxLen
    local label = uiElements.label(options.displayName or name)
    formField.contents = {}
    formField.field = uiElements.field(getLabelString(formField, value, options.maxLen), function() end):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local contextMenuOptions = options.contextMenuOptions or
        { mode = "focused", shouldShowMenu = function() return true end }
    local fieldWithContext = contextMenu.addContextMenu(formField.field, function()
        local language = languageRegistry.getLanguage()
        local formElements = getSubformElements(formField, formField:getValue(), options)
        local columnElements = {}
        if #formElements > 0 then
            local columnCount = (formElements[1].width or 0) + 1
            local formOptions = {
                columns = columnCount,
                formFieldChanged = function(fields)
                    local data = form.getFormData(fields)
                    formField:setValue(data)
                    formField.isValid = form.formValid(fields)
                    updateTextField(formField, data, options)
                end
            }
            form.prepareFormFields(formElements, formOptions)
            local formGrid = form.getFormFieldsGrid(formElements, formOptions)

            table.insert(columnElements, formGrid)
        end
        if not options.setLength then
            local addButton = uiElements.button(
                tostring(language.forms.fieldTypes.list.addButton),
                valueAddRowHandler(formField)
            )
            if #formElements > 0 then
                addButton:with(uiUtils.fillWidth(false))
            end

            table.insert(columnElements, addButton)
        end

        local column = uiElements.column(columnElements)

        return column
    end, contextMenuOptions)
    formField.currentValue = value
    formField.elements = { label, fieldWithContext }
    formField.width = 2
    formField.isValid = true
    setmetatable(formField, listField._MT)
    return formField
end

return listField
