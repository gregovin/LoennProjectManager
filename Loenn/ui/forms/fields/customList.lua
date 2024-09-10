local ui = require("ui")
local uiElements = require("ui.elements")
local uiUtils = require("ui.utils")

local stringField = require("ui.forms.fields.string")
local utils = require("utils")
local iconUtils = require("ui.utils.icons")
local contextMenu = require("ui.context_menu")
local form = require("ui.forms.form")
local languageRegistry = require("language_registry")
local logging = require("logging")

local listField = {}

listField.fieldType = "loennProjectManager.list"

---@class Options
---@field elementSeparator string
---@field elementDefault string
---@field elementOptions table

---Split a string with some seperator into its components
---@param txt string
---@param options Options
---@return string[]
local function getValueParts(txt, options)
    if txt == nil then
        return {}
    end
    local separator = options.elementSeparator
    local parts = string.split(txt, separator)()

    -- Special case for empty string and empty default
    -- Otherwise we will never be able to add when the field is empty
    if txt == "" and options.elementDefault == "" then
        table.insert(parts, "")
    end

    return parts
end

---Join a list of things into a string
---@param parts string[]
---@param options Options
---@return string
local function joinValueParts(parts, options)
    local joined = table.concat(parts, options.elementSeparator)

    return joined
end
---@class ListFormElement
---@field contextWindow unknown
---@field realValue any[]
---@field options Options
---@field field unknown
---@field _subElements unknown[]
---@field _previousValue any[]?
---@field subFormValid boolean?

---Update the context window
---@param formField ListFormElement
---@param options Options
local function updateContextWindow(formField, options)
    local content = listField.buildContextMenu(formField, options)
    local contextWindow = formField.contextWindow

    if contextWindow and contextWindow.parent then
        contextWindow.children[1]:removeSelf()
        contextWindow:addChild(content)

        -- Make sure the element is considered hovered and focused
        -- Otherwise the context menu will dispose of our injected content
        ui.hovering = content
        ui.focusing = content
    end
end

---Construct the delete row handler callback
---@param formField ListFormElement
---@param index integer
---@return function
local function valueDeleteRowHandler(formField, index)
    return function()
        local value = formField.realValue
        local options = formField.options
        local field = formField.field

        table.remove(value, index)

        local joined = joinValueParts(value, options)

        field:setText(joined)

        updateContextWindow(formField, options)
    end
end

---Construct the add row handler
---@param formField ListFormElement
---@return function
local function valueAddRowHandler(formField)
    return function()
        local value = formField.realValue
        local options = formField.options
        local field = formField.field

        table.insert(value, options.elementDefault or "")

        local joined = joinValueParts(value, options)

        field:setText(joined)
        updateContextWindow(formField, options)
    end
end

---Get the sub elements of the list
---@param formField ListFormElement
---@param value string
---@param options Options
---@return table
local function getSubFormElements(formField, value, options)
    local language = languageRegistry.getLanguage()
    local elements = {}
    local parts = getValueParts(value, options)

    local baseFormElement = form.getFieldElement("base", options.elementDefault or "", options.elementOptions)
    local valueTransformer = baseFormElement.valueTransformer or function(x) return x end

    for i, part in ipairs(parts) do
        local formElement = form.getFieldElement(tostring(i), valueTransformer(part) or part, options.elementOptions)

        -- Remove label if based on string field
        if formElement.elements[1] == formElement.label then
            formElement.width = 1

            table.remove(formElement.elements, 1)
        end

        -- Fake remove button as a form field
        local removeButton = uiElements.button(
            tostring(language.forms.fieldTypes.list.removeButton),
            valueDeleteRowHandler(formField, i)
        )
        local fakeElement = {
            elements = {
                removeButton
            },
            fieldValid = function()
                return true
            end
        }

        table.insert(elements, formElement)
        table.insert(elements, fakeElement)
    end

    return elements
end

---Update the overal field
---@param formField ListFormElement
---@param formData table
---@param options Options
local function updateTextfield(formField, formData, options)
    local data = {}

    for k, v in pairs(formData) do
        data[tonumber(k)] = v
    end

    local joined = joinValueParts(data, options)
    formField.realValue = data

    formField.field:setText(joined)
end

---Get the form data
---@param fields any[]
---@return table
local function getFormDataStrings(fields)
    local data = {}

    for _, field in ipairs(fields) do
        local i = #data + 1
        data[i] = field:getValue()
    end

    return data
end

---Update the sub elements
---@param formField ListFormElement
---@param options Options
---@return table
function listField.updateSubElements(formField, options)
    if not formField then
        formField._subElements = {}

        return formField._subElements
    end

    local value = formField.realValue

    if not value then
        formField._subElements = {}

        return formField._subElements
    end

    local previousValue = formField._previousValue
    local formElements = formField._subElements

    if value ~= previousValue then
        formElements = getSubFormElements(formField, joinValueParts(value, options), options)
    end

    formField._subElements = formElements
    formField._previousValue = value

    return formElements
end

---Build the context menu for the form
---@param formField ListFormElement
---@param options Options
---@return unknown
function listField.buildContextMenu(formField, options)
    local language = languageRegistry.getLanguage()
    local formElements = formField._subElements
    local columnElements = {}

    if #formElements > 0 then
        local columnCount = (formElements[1].width or 0) + 1
        local formOptions = {
            columns = columnCount,
            formFieldChanged = function(fields)
                -- Get value raw instead, we need the string, not the "validated" data
                local data = getFormDataStrings(fields)

                formField.subFormValid = form.formValid(fields)
                updateTextfield(formField, data, options)
            end,
        }

        form.prepareFormFields(formElements, formOptions)

        local formGrid = form.getFormFieldsGrid(formElements, formOptions)

        table.insert(columnElements, formGrid)
    end

    local addButton = uiElements.button(
        tostring(language.forms.fieldTypes.list.addButton),
        valueAddRowHandler(formField)
    )

    if #formElements > 0 then
        addButton:with(uiUtils.fillWidth(false))
    end

    table.insert(columnElements, addButton)

    local column = uiElements.column(columnElements)

    return column
end

local function addContextSpawner(formField, options)
    local field = formField.field
    local contextMenuOptions = options.contextMenuOptions or {
        mode = "focused"
    }

    if field.height == -1 then
        field:layout()
    end

    local iconMaxSize = field.height - field.style.padding
    local parentHeight = field.height
    local menuIcon, iconSize = iconUtils.getIcon("list", iconMaxSize)

    if menuIcon then
        local centerOffset = math.floor((parentHeight - iconSize) / 2) + 1
        local folderImage = uiElements.image(menuIcon):with(uiUtils.rightbound(-1)):with(uiUtils.at(0, centerOffset))

        folderImage.interactive = 1
        folderImage:hook({
            onClick = function(orig, self)
                orig(self)

                local contextWindow = contextMenu.showContextMenu(listField.buildContextMenu(formField, options),
                    contextMenuOptions)

                formField.contextWindow = contextWindow
            end
        })

        field:addChild(folderImage)
    end
end

function listField.getElement(name, value, options)
    -- Add extra options and pass it onto string field
    options = table.shallowcopy(options or {})

    options.elementOptions = options.elementOptions or {}
    options.elementSeparator = options.elementSeparator or ","
    options.minimumElements = options.minimumElements or 0
    options.maximumElements = options.maximumElements or math.huge

    if not options.elementOptions.fieldType then
        options.elementOptions.fieldType = options.elementOptions.fieldType or "string"
    end

    local formField

    options.validator = function(v)
        if not formField then
            return true
        end
        local subElements = listField.updateSubElements(formField, options)

        -- Do not trust the length of sub elements, might contain delete buttons
        local value = formField.realValue


        if #value < options.minimumElements or #value > options.maximumElements then
            return false
        end

        return form.formValid(subElements)
    end

    formField = stringField.getElement(name, joinValueParts(value, options), options)

    formField.options = options
    formField.realValue = value
    listField.updateSubElements(formField, options)
    addContextSpawner(formField, options)

    return formField
end

return listField
