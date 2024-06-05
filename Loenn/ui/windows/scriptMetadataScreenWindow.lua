local uiElements = require("ui.elements")
local windowPersister = require("ui.window_position_persister")
local languageRegistry = require("language_registry")
local formUtils = require("ui.utils.forms")
local mods = require("mods")
local listWidgets = require("ui.widgets.lists")
local layer = mods.requireFromPlugin("metadataEntries.layer")
local uiLayer = mods.requireFromPlugin("metadataEntries.ui")
local unused = mods.requireFromPlugin("metadataEntries.unused")
local frame = mods.requireFromPlugin("metadataEntries.frame")
local frameStruct = mods.requireFromPlugin("metadataStructs.frame")
local layerStruct = mods.requireFromPlugin("metadataStructs.layer")
local uiStruct = mods.requireFromPlugin("metadataStructs.ui")
local widgetUtils = require("ui.widgets.utils")
local uiUtils = require("ui.utils")
local unusedStruct = mods.requireFromPlugin("metadataStructs.unused")
local form = require("ui.forms.form")
local atlases = require("atlases")
local logging = require("logging")
local utils = require("utils")

local windowPersisterName = "metadata_screen_window"

local metadataScreenWindow = {}
local frameOptions = {}
local metadataWindowGroup
-- TODO - Layouting variables that should be more dyanmic
local PREVIEW_MAX_WIDTH = 320 * 3
local PREVIEW_MAX_HEIGHT = 180 * 3
local WINDOW_STATIC_HEIGHT = 640
---@class EntryData
---@field entry Item
---@field parentEntry Item
---@field used boolean

---@class Entry
---@field text any
---@field data EntryData

---@class Item
---@field children Item[]?
---@field displayName string

local fileClaims = {}
---Get a list of items
---@param targets Item[]
---@param items Entry[]
---@param parent Item?
---@return Entry[]
local function getEntryItems(targets, items, parent)
    local language = languageRegistry.getLanguage()

    items = items or {}
    local lastLayer = 0
    for i, item in ipairs(targets) do
        local itemType = utils.typeof(item)

        if itemType == "layer" then
            local displayName = layer.displayName(language, item)
            local listItem = uiElements.label(displayName)


            if item.children then
                getEntryItems(item.children, items, item)
            end
            table.insert(items,
                {
                    text = listItem,
                    data = {
                        entry = item,
                        parentEntry = parent,
                        used = true,
                    }
                })
            lastLayer = i
        elseif itemType == "ui" then
            local displayName = uiLayer.displayName(language, item)
            local listItem = uiElements.label(displayName)
            table.insert(items, {
                text = listItem,
                data = {
                    entry = item,
                    parentEntry = parent,
                    used = true
                }
            })
        elseif itemType == "unused" then
            local displayName = unused.displayName(language, item)
            local listItem = uiElements.label(displayName)
            table.insert(items, {
                text = listItem,
                data = {
                    entry = item,
                    parentEntry = parent,
                    used = false
                }
            })
        elseif itemType == "frame" then
            local displayName = frame.displayName(language, item)
            local listItem = uiElements.label(displayName)
            local fname = frame.fileName(item)
            if fname then
                fileClaims[fname] = fileClaims[fname] and fileClaims[fname] + 1 or 0
            end
            table.insert(items {
                text = listItem,
                data = {
                    entry = item,
                    parentEntry = items[lastLayer] or parent,
                    used = true,
                }
            })
        end
    end
    return items
end
---Return an item's handler
---@param item Item
---@return Handler
local function getHandler(item)
    local itemType = utils.typeof(item)
    if itemType == "layer" then
        return layer
    elseif itemType == "ui" then
        return uiLayer
    elseif itemType == "frame" then
        return frame
    else
        return unused
    end
end

local function getOptions(item)
    local handler = getHandler(item)
    local prepareOptions = {
        namePath = { "attribute" },
        tooltipPath = { "description" },
    }
    local dummyData, fieldInformation, fieldOrder = formUtils.prepareFormData(handler, item, prepareOptions, { item })
    local options = {
        fields = fieldInformation,
        fieldOrder = fieldOrder
    }
    if utils.typeof(item) == "frame" then
        options.fields.texture.options = frameOptions
    end
    return options, dummyData
end
---@class ListTarget
---@field entry Item
---@field defaultTarget boolean
---@field parentEntry Item?
---@field used boolean
---@class MovementButtonElements
---@field up unknown
---@field down unknown

---@class MethodInfo
---@field method string
---@field correctUsedValue boolean
---@field name string?

---@class InteractionData
---@field formData table
---@field addNewMethod MethodInfo
---@field listTarget ListTarget
---@field items Item[]
---@field itemListElement unknown
---@field formContainerGroup unknown
---@field movementButtonElements MovementButtonElements
---@field itemPreviewGroup unknown

---Get the item Preview for the selected item
---@param interactionData InteractionData
---@return any
function metadataScreenWindow.getItemPreview(interactionData)
    local language = languageRegistry.getLanguage()
    local formData = interactionData.formData
    local listTarget = interactionData.listTarget
    local item = listTarget and listTarget.entry or {}
    local itemType = utils.typeof(item)
    if not formData then --not ready yet
        return
    end

    if itemType == "frame" then
        local texture = formData.texture
        local sprite = atlases.getResource(texture)

        if sprite then
            local color = formData.color
            local imageElement = uiElements.image(sprite.image, sprite.quad, sprite.layer)

            if color then
                local success, r, g, b, a = utils.parseHexColor(color)
                if success then
                    imageElement.style.color = { r, g, b, a }
                end
            end
            --update image size
            imageElement:layout()
            local imageWidth, imageHeight = imageElement.width / imageElement.scaleX,
                imageElement.height / imageElement.scaleY
            local bestScale = utils.getBestScale(imageWidth, imageHeight, PREVIEW_MAX_WIDTH, PREVIEW_MAX_HEIGHT)

            imageElement.scaleX = bestScale
            imageElement.scaleY = bestScale
            return imageElement
        else
            return uiElements.label(tostring(language.ui.metadata_screen_window.preview.unknown_texture))
        end

        return uiElements.label(formData.texture or formData._name or
            tostring(language.ui.metadata_screen_window.preview.no_preview))
    end
end

---Update the item preview
---@param interactionData InteractionData
function metadataScreenWindow.updateItemPreview(interactionData)
    local previewContainer = interactionData.itemPreviewGroup
    local newPreview = metadataScreenWindow.getItemPreview(interactionData)

    if previewContainer.children[1] then
        previewContainer:removeChild(previewContainer.children[1])
    end

    if newPreview then
        previewContainer:addChild(newPreview)
    end
end

---Get the form data for the selected element
---@param interactionData InteractionData
---@return table
local function prepareFormData(interactionData)
    local listTarget = interactionData.listTarget
    local formData = {}

    if not listTarget then
        return formData
    end

    local item = listTarget.entry or {}
    local parentItem = listTarget.parentEntry or {}

    --copy parent item
    for k, v in pairs(parentItem) do
        formData[k] = v
    end
    formData.__name = nil
    formData._type = nil

    --copy the item
    for k, v in pairs(item) do
        formData[k] = v
    end

    --ignore children
    if type(formData.children) == "table" then
        formData.children = nil
    end

    local handler = getHandler(item)
    local defaultData = handler.defaultData(item) or {}

    for k, v in pairs(defaultData) do
        if formData[k] == nil then formData[k] = v end
    end
    return formData
end
---Apply Newdata
---@param item Item
---@param newData table
local function applyFormChanges(item, newData)
    for k, v in pairs(newData) do
        item[k] = v
    end
end

---comment
---@param interactionData InteractionData
---@return Item[]?
---@return Item[]?
---@return integer?
---@return Item?
local function findItemInMetadata(interactionData)
    local listTarget = interactionData.listTarget

    if not listTarget then return end

    local items = interactionData.items
    local item = listTarget.entry

    for i, s in ipairs(items) do
        local stype = utils.typeof(s)

        if item == s then
            return items, items, i
        end

        if stype == "layer" then
            for j, c in ipairs(s.children or {}) do
                if item == c then
                    return items, s.children, j, s
                end
            end
        end

        return items, items, 1
    end
end
---@class ListItem: EntryData
---@field onClick fun(self: ListItem, i: integer, j: integer, k: integer)
---@field removeSelf fun(self: ListItem)
---@field text string

---Find the currently selected list item
---@param interactionData InteractionData
---@return ListItem?
---@return integer?
local function findCurrentListItem(interactionData)
    local listTarget = interactionData.listTarget
    local listElement = interactionData.itemListElement

    for i, item in ipairs(listElement.children) do
        if item.data == listTarget then
            return item, i
        end
    end
end
---Get the count of used items
---@param interactionData InteractionData
---@return integer
local function usedListItemCount(interactionData)
    local listElement = interactionData.itemListElement
    local count = 0

    for _, item in ipairs(listElement.children) do
        if item.data.used then
            count += 1
        end
    end
    return count
end
---Set the selection and run the appropriate callback
---@param listElement unknown
---@param index integer
---@return unknown
local function setSelectionWithCallback(listElement, index)
    listElement:setSelectedIndex(utils.clamp(index, 1, #listElement.children))

    local newSelection = listElement.selected

    if newSelection then
        -- Trigger list item callback
        newSelection:onClick(0, 0, 1)
    end

    return newSelection
end
---Move the item at index before to index after in t
---@param t table
---@param before integer
---@param after integer
local function moveIndex(t, before, after)
    local value = table.remove(t, before)

    table.insert(t, after, value)
end
---Check if we are able to move the item
---@param interactionData InteractionData
---@param offset integer
---@return boolean
local function canMoveItem(interactionData, offset)
    local listTarget = interactionData.listTarget

    if not listTarget or listTarget.defaultTarget then return false end
    local items, parent, index = findItemInMetadata(interactionData)
    if parent and index then
        local newIndex = index + offset
        return index ~= newIndex and newIndex >= 1 and newIndex <= #parent
    end

    return false
end
---Update the movement buttons
---@param interactionData InteractionData
local function updateMovementButtons(interactionData)
    local moveUpButton = interactionData.movementButtonElements.up
    local moveDownButton = interactionData.movementButtonElements.down

    if moveUpButton and moveDownButton then
        moveUpButton:formSetEnabled(canMoveItem(interactionData, -1))
        moveDownButton:formSetEnabled(canMoveItem(interactionData, 1))
    end
end
---Actually Move an item
---@param interactionData InteractionData
---@param offset integer
local function moveItem(interactionData, offset)
    local items, parent, index = findItemInMetadata(interactionData)

    if parent and index then
        local newIndex = utils.clamp(index + offset, 1, #parent)

        if index ~= newIndex then
            local listElement = interactionData.itemListElement
            local listItem, listIndex = findCurrentListItem(interactionData)
            listIndex = listIndex or 1
            moveIndex(parent, index, newIndex)
            moveIndex(listElement.children, listIndex, listIndex + offset)

            listElement:reflow()

            updateMovementButtons(interactionData)
        end
    end
end
---Change weather an item is used
---@param interactionData InteractionData
local function changeItemUsed(interactionData)
    local listTarget = interactionData.listTarget
    local listElement = interactionData.itemListElement
    local listItem, listIndex = findCurrentListItem(interactionData)
    if not listIndex then error("oops!") end
    if not listItem then error("oops!") end
    local moveUpButton = interactionData.movementButtonElements.up
    local moveDownButton = interactionData.movementButtonElements.down
    local used = listItem.used
    local usedCount = usedListItemCount(interactionData)

    local items, parent, index, parentItem = findItemInMetadata(interactionData)
    local parentType = utils.typeof(parentItem)

    local movedItem = listTarget.entry
    local insertionIndex = used and #listElement.children or usedCount + 1
    moveIndex(listElement.children, listIndex, insertionIndex)
    listElement:reflow()
    listItem:onClick(0, 0, 1)
end
---@return Item
local function createFrame()
    local item = frameStruct.decode()
    local defaultData = frame.defaultData(item) or {}

    for k, v in pairs(defaultData) do
        item[k] = v
    end
    return item
end
---@return Item
local function createLayer()
    local item = layerStruct.decode()
    local defaultData = layer.defaultData(item) or {}
    for k, v in pairs(defaultData) do
        item[k] = v
    end
    return item
end
---@return Item
local function createUi()
    local item = uiStruct.decode()
    local defaultData = uiLayer.defaultData(item) or {}

    for k, v in pairs(defaultData) do
        item[k] = v
    end
    return item
end
---@param name string?
---@return Item
local function createUnused(name)
    local item = unusedStruct.decode({ file = name })
    local defaultData = unused.defaultData(item) or {}

    for k, v in pairs(defaultData) do
        item[k] = v
    end
    return item
end
---Create a default list
---@return ListTarget
local function getDefaultListTarget()
    return {
        entry = createUnused(),
        used = true,
        defaultTarget = true
    }
end
---Add a new item to the list
---@param interactionData InteractionData
---@param formFields table
---@return boolean
local function addNewItem(interactionData, formFields)
    local listTarget = interactionData.listTarget

    local newItem
    local currentItem = listTarget.entry
    local parentEntry = listTarget.parentEntry

    local moveUpButton = interactionData.movementButtonElements.up
    local moveDownButton = interactionData.movementButtonElements.down

    local listElement = interactionData.itemListElement

    local used = listTarget.used
    local method = interactionData.addNewMethod.method
    local correctUsedValue = interactionData.addNewMethod.correctUsedValue

    if method == "basedOnCurrent" then
        if currentItem then
            newItem = table.shallowcopy(currentItem)

            applyFormChanges(newItem, form.getFormData(formFields))
        end
    elseif method == "layer" then
        newItem = createLayer()
    elseif method == "frame" then
        newItem = createFrame()
    elseif method == "unused" then
        newItem = createUnused(interactionData.addNewMethod.name or "")
    elseif method == "ui" then
        newItem = createUi()
    end
    if newItem then
        local items, parrentTable, index = findItemInMetadata(interactionData)
        if not parrentTable then error("oops, this shouldn't happen!") end
        local _, listIndex = findCurrentListItem(interactionData)
        local listItems = getEntryItems({ newItem }, {}, nil)

        if #listElement.children == 0 then
            parrentTable = interactionData.items
            listIndex = 0
            index = 0
        end
        for i, item in ipairs(listItems) do
            local listItem = uiElements.listItem(item.text, item.data)
            listItem.owner = listItems

            table.insert(listItem.children, listIndex + i, listItem)
        end
        table.insert(parrentTable, index + 1, newItem)
        if #listItems > 0 then
            local lastItem = listElement.children[listIndex + #listItems]

            listElement:reflow()
            lastItem:onClick(0, 0, 1)

            if correctUsedValue == false then
                changeItemUsed(interactionData)
            end
        end
    end
    return not not newItem
end
---Remove the selected item now
---@param interactionData InteractionData
local function removeItem(interactionData)
    local items, parent, index = findItemInMetadata(interactionData)

    if parent and index then
        local listElement = interactionData.itemListElement
        local listItem, listIndex = findCurrentListItem(interactionData)
        if not listItem or not listIndex then error("oops") end
        table.remove(parent, index)
        listItem:removeSelf()
        local fakeInteractionData = table.shallowcopy(interactionData)
        while utils.typeof(parent[index]) == "frame" do
            local fileName = frame.fileName(parent[index])
            if fileName then
                fileClaims[fileName] = fileClaims[fileName] and fileClaims[fileName] > 0 and fileClaims[fileName] - 1 or
                    0
            end
            table.remove(parent, index)
            listElement:removeChild(listElement.children[index])
            if (not fileClaims[fileName]) or fileClaims[fileName] == 0 then
                local lt = interactionData.listTarget
                local used = lt.used
                fakeInteractionData.addNewMethod = {
                    method = "unused",
                    correctUsedValue = used ~= false,
                    name = fileName
                }
                addNewItem(fakeInteractionData, metadataScreenWindow.getMetadataFrom(interactionData))
            end
        end
        if #listElement.children > 0 then
            setSelectionWithCallback(listElement, listIndex)
        else
            interactionData.listTarget = getDefaultListTarget()

            metadataScreenWindow.updateMetadataForm(interactionData)
            metadataScreenWindow.updateItemPreview(interactionData)
        end
    end
end
---Update the text to that for a given item
---@param listItem ListItem
---@param item Item
local function updateListItemText(listItem, item)
    if not listItem then return end
    local language = languageRegistry.getLanguage()

    local handler = getHandler(item)
    listItem.text = handler.displayName(language, item)
end
---Update the given item with new data
---@param interactionData InteractionData
---@param item Item
---@param newData table
local function updateItem(interactionData, item, newData)
    local listElement = interactionData.itemListElement
    local listItem = listElement and listElement.selected

    applyFormChanges(item, newData)
    updateListItemText(listItem, item)
end
---Get the dropdown options for the current item
---@param item Item
---@param usingDefault boolean
---@return table
local function getNewDropdownOptions(item, usingDefault)
    local language = languageRegistry.getLanguage()
    local options = {}

    if item and not usingDefault then
        table.insert(options, {
            text = tostring(language.ui.metadata_screen_window.new_options.based_on_current),
            data = {
                method = "basedOnCurrent"
            }
        })
    end

    table.insert(options, {
        text = tostring(language.ui.metadata_screen_window.new_options.layer),
        data = {
            method = "layer"
        }
    })
    if utils.typeof(item) == "layer" then
        table.insert(options {
            text = tostring(language.ui.metadata_screen_window.new_options.frame),
            data = {
                method = "frame"
            }
        })
    end
    table.insert(options, {
        text = tostring(language.ui.metadata_screen_window.new_options.ui),
        data = {
            method = "ui"
        }
    })
    table.insert(options, {
        text = tostring(language.ui.metadata_screen_window.new_options.unused),
        data = {
            method = "unused"
        }
    })
    return options
end
---Get the form buttons
---@param interactionData InteractionData
---@param formFields table
---@param formOptions table
---@return unknown
local function getMetadataScreenFormButtons(interactionData, formFields, formOptions)
    local listTarget = interactionData.listTarget or {}
    local listHasElements = false

    if interactionData.itemListElement then
        listHasElements = #interactionData.itemListElement.children > 0
    end

    local language = languageRegistry.getLanguage()
    local item = listTarget.entry
    local used = listTarget.used
    local isDefaultTarget = listTarget.defaultTarget

    local handler = getHandler(item)

    local movementButtonElements = {}

    local buttons = {
        {
            text = tostring(language.ui.metadata_screen_window.form.new),
            callback = function()
                addNewItem(interactionData, formFields)
            end
        },
        {
            text = tostring(language.ui.metadata_screen_window.form.remove),
            enabled = listHasElements,
            callback = function()
                removeItem(interactionData)
            end
        },
        {
            text = tostring(language.ui.metadata_screen_window.form.update),
            formMustBeValid = true,
            enabled = listHasElements,
            callback = function()
                updateItem(interactionData, item, form.getFormData(formFields))
            end
        },
        {
            text = tostring(language.ui.metadata_screen_window.form.move_up),
            enabled = canMoveItem(interactionData, -1),
            callback = function()
                moveItem(interactionData, -1)
            end
        },
        {
            text = tostring(language.ui.metadata_screen_window.form.move_down),
            enabled = canMoveItem(interactionData, 1),
            callback = function()
                moveItem(interactionData, 1)
            end
        },
    }

    local buttonRow = form.getFormButtonRow(buttons, formFields, formOptions)
    local newDropdownItems = getNewDropdownOptions(item, isDefaultTarget)
    local newDropdown = uiElements.dropdown(newDropdownItems, function(item, data)
        interactionData.addNewMethod = data
    end)
    movementButtonElements.up = buttonRow.children[4]
    movementButtonElements.down = buttonRow.children[5]
    interactionData.addNewMethod = newDropdownItems[1].data
    interactionData.movementButtonElements = movementButtonElements
    table.insert(buttonRow.children, 1, newDropdown)
    return buttonRow
end
---Get the form info
---@param interactionData InteractionData
---@return unknown
function metadataScreenWindow.getMetadataFrom(interactionData)
    local formData = prepareFormData(interactionData)
    local formOptions, dummyData = getOptions(formData)

    formOptions.columns = 8
    formOptions.formFieldChanged = function(formFields, field)
        local newData = form.getFormData(formFields)

        interactionData.formData = newData

        metadataScreenWindow.updateItemPreview(interactionData)
    end

    local formBody, formFields = form.getFormBody(dummyData, formOptions)
    local buttonRow = getMetadataScreenFormButtons(interactionData, formFields, formOptions)

    return uiElements.column({ formBody, buttonRow })
end

---Update the form
---@param interactionData InteractionData
function metadataScreenWindow.updateItemForm(interactionData)
    local formContainer = interactionData.formContainerGroup
    local newForm = metadataScreenWindow.getMetadataFrom(interactionData)

    if formContainer.children[1] then
        formContainer:removeChild(formContainer.children[1])
    end
    formContainer:addChild(newForm)
end

---Check if an item can be dragged
---@param interactionData InteractionData
---@param fromList any
---@param fromListItem any
---@param toList any
---@param toListItem any
---@param fromIndex integer
---@param toIndex integer
---@return boolean
---@return integer
---@return InteractionData? fakeInteractionData
local function listItemDragAllowed(interactionData, fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
    local offset = toIndex - fromIndex

    if toIndex > fromIndex then
        offset -= 1
    end

    if offset ~= 0 then
        local fakeInteractionData = table.shallowcopy(interactionData)

        fakeInteractionData.listTarget = fromListItem.data
        fakeInteractionData.itemListElement = fromList

        return canMoveItem(fakeInteractionData, offset), offset, fakeInteractionData
    end

    return false, offset, nil
end
---Get the drag handler
---@param interactionData InteractionData
---@return function
local function listItemDraggedHandler(interactionData)
    return function(fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
        local allowed, offset, fakeInteraction = listItemDragAllowed(interactionData, fromList, fromListItem, toList,
            toListItem, fromIndex, toIndex)

        if allowed and fakeInteraction then
            moveItem(fakeInteraction, offset)

            -- Force update movement buttons with the real data
            -- We might have moved in a way that should disable/enable some buttons
            updateMovementButtons(interactionData)
        end

        -- Manually update the list
        return false
    end
end
---Get a drag check handler
---@param interactionData InteractionData
---@return function
local function listItemCanInsertHandler(interactionData)
    return function(fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
        return listItemDragAllowed(interactionData, fromList, fromListItem, toList, toListItem, fromIndex, toIndex)
    end
end
---Get the list of items in the map
---@param map Item[]
---@param interactionData InteractionData
---@return unknown column
---@return unknown list
function metadataScreenWindow.getItemList(map, interactionData)
    local items = {}
    getEntryItems(map, items, nil)
    local listOptions = {
        initialItem = 1,
        draggable = true,
        listItemDragged = listItemDraggedHandler(interactionData),
        listItemCanInsert = listItemCanInsertHandler(interactionData)
    }
    local column, list = listWidgets.getList(function(element, listItem)
        interactionData.listTarget = listItem
        interactionData.formData = prepareFormData(interactionData)

        metadataScreenWindow.updateItemForm(interactionData)
        metadataScreenWindow.updateItemPreview(interactionData)
    end, items, listOptions)

    return column, list
end

---Get the window content
---@param map Item[]
---@return unknown layout
---@return InteractionData
function metadataScreenWindow.getWindowContent(map)
    local interactionData = {}
    interactionData.listTarget = getDefaultListTarget()

    local itemFormGroup = uiElements.group({}):with(uiUtils.bottombound)
    local itemListColumn, itemList = metadataScreenWindow.getItemList(map, interactionData)
    local itemPreview = uiElements.group({
        metadataScreenWindow.getItemPreview(interactionData)
    })
    local itemForm = metadataScreenWindow.getMetadataFrom(interactionData)
    itemFormGroup:addChild(itemForm)
    interactionData.formContainerGroup = itemFormGroup
    interactionData.itemPreviewGroup = itemPreview
    interactionData.itemListElement = itemList

    local itemListPreviewRow = uiElements.row({
        itemListColumn:with(uiUtils.fillHeight(false)),
        itemPreview
    })
    local layout = uiElements.column({
        itemListPreviewRow,
        itemFormGroup
    }):with(uiUtils.fillHeight(true))

    layout:reflow()
    return layout, interactionData
end

function metadataScreenWindow.editMetadataScreen(map, title)
    frame.getImgageNames()
    if not map then return end

    local window
    local layout, interactionData = metadataScreenWindow.getWindowContent(map)
    window = uiElements.window(title, layout):with({
        height = WINDOW_STATIC_HEIGHT
    })
    local windowCloseCallback = windowPersister.getWindowCloseCallback(windowPersisterName)
    windowPersister.trackWindow(windowPersisterName, window)
    metadataWindowGroup = uiElements.group({})
    metadataWindowGroup.parent:addChild(window)
    widgetUtils.addWindowCloseButton(window, windowCloseCallback)
    return window
end

return metadataScreenWindow
