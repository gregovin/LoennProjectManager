local uiElements= require("ui.elements")
local contextMenu = require("ui.context_menu")
local mods = require("mods")
local expandableGrid = mods.requireFromPlugin("ui.widgets.expandableGrid")

local dictionaryField = {}
dictionaryField.fieldType="loennProjectManager.dictionary"
dictionaryField._MT={}
dictionaryField._MT.__index={}
local warningStyle = {
    normalBorder = {0.65, 0.5, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.67, 0.2, 1.0, 2.0}
}
local invalidStyle = {
    normalBorder = {0.65, 0.2, 0.2, 0.9, 2.0},
    focusedBorder = {0.9, 0.2, 0.2, 1.0, 2.0}
}
local function getLabelString(keys,values)
    local out = ""
    local sep=""
    for i,k in ipairs(keys) do
        out=out..sep..k..": "..values[i]
        sep = ", "
    end
    return out
end
function dictionaryField._MT.__index:setValue(value)
    for i,k in ipairs(value.keys) do
        self.currentText.keys[i]=self.keyDisplayTransformer(k)
        self.keys[i]:setText(self.currentText.keys[i])
    end
    for i,v in ipairs(value.values) do
        self.currentText.values[i]=self.valueDisplayTransformer(v)
        self.values[i]:setText(self.currentText.values[i])
    end
    self.field:setText(getLabelString(self.currentText.keys,self.currentText.values))
    self.currentValue = value
end
function dictionaryField._MT.__index:getValue()
    return self.currentValue
end
function dictionaryField._MT.__index:getCurrentText()
    return self.currentText
end
function dictionaryField._MT.__index:getKey(idx)
    return self:getValue().keys[idx]
end
function dictionaryField._MT.__index:getIndividualValue(idx)
    return self:getValue().values[idx]
end
function dictionaryField._MT.__index:getKeyText(idx)
    return self:getCurrentText() and self:getCurrentText().keys[idx] or self:getKey(idx)
end
function dictionaryField._MT.__index:getValueText(idx)
    return self:getCurrentText() and self:getCurrentText().values[idx] or self:getIndividualValue(idx)
end
function dictionaryField._MT.__index:keyValid(idx)
    return self.keyValidator(self:getKey(idx),self:getKeyText(idx))
end
function dictionaryField._MT.__index:xg(idx)
    return self.keyWarning(self:getKey(idx),self:getKeyText(idx))
end
function dictionaryField._MT.__index:valueValid(idx)
    return self.valueValidator(self:getIndividualValue(idx),self:getValueText(idx))
end
function dictionaryField._MT.__index:valueWarning(idx)
    return self.valueWarning(self:getIndividualValue(idx),self:getValueText(idx))
end
function dictionaryField._MT.__index:fieldValid()
    for idx=1,#self.currentValue.keys,1 do
        if not (self:keyValid(idx) and self:valueValid(idx)) then
            return false
        end
    end
    return true
end
function dictionaryField._MT.__index:fieldWarning()
    for idx=1,#self.currentValue.keys,1 do
        if not (self:keyWarning(idx) and self:valueWarning(idx)) then
            return false
        end
    end
    return true
end
local function updateFieldStyle(formfield)
    local validVisuals = formfield.validVisuals
    local warnVisuals = formfield.warnVisuals
    for idx=1,#formfield.currentValue.keys,1 do
        local kvalid = formfield:keyValid(idx)
        local kwarn = formfield:keyWarning(idx)
        local vvalid = formfield:valueValid(idx)
        local vwarn = formfield:valueWarning(idx)

        local kNeedsChanged = validVisuals.keys[idx] ~= kvalid or warnVisuals.keys[idx] ~= kwarn
        local vNeedsChanged = validVisuals.values[idx] ~= vvalid or warnVisuals.values[idx] ~= vwarn
        if kNeedsChanged then
            if not kvalid then
                formfield.keys[idx].style = invalidStyle
            elseif not kwarn then
                formfield.keys[idx].style = warningStyle
            else
                formfield.keys[idx].style = nil
            end
            formfield.validVisuals.keys[idx] = kvalid
            formfield.warnVisuals.keys[idx] = kwarn
            formfield.keys[idx]:repaint()
        end
        if vNeedsChanged then
            if not vvalid then
                formfield.values[idx].style = invalidStyle
            elseif not vwarn then
                formfield.values[idx].style = warningStyle
            else
                formfield.values[idx].style = nil
            end
            formfield.validVisuals.values[idx] = vvalid
            formfield.warnVisuals.values[idx] = vwarn
            formfield.values[idx]:repaint()
        end
    end
    local overValidVisuals = formfield.overValidVisuals
    local overWarnVisuals = formfield.overWarnVisuals
    local valid = formfield:fieldValid()
    local warn = formfield:fieldWarning()
    local needsChanged = overValidVisuals~=valid or overWarnVisuals~=warn
    if needsChanged then
        if not valid then
            formfield.field.style = invalidStyle
        elseif not warn then
            formfield.field.style = warningStyle
        else
            formfield.field.style = nil
        end
        formfield.overValidVisuals = valid
        formfield.overWarnVisuals = warn
        formfield.field:repaint()
    end
end

local function keyChanged(formfield,idx)
    return function(element,new,old)
        formfield.currentValue.keys[idx] = formfield.keyTransformer(new)
        formfield.currentText.keys[idx] = new
        formfield.field:setText(getLabelString(formfield.currentText.keys,formfield.currentText.values)) 
        updateFieldStyle(formfield)
        formfield:notifyFieldChanged()
    end
end
local function valueChanged(formfield,idx)
    return function(element,new,old)
        formfield.currentValue.values[idx] = formfield.valueTransformer(new)
        formfield.currentText.values[idx] = new
        formfield.field:setText(getLabelString(formfield.currentText.keys,formfield.currentText.values))
        updateFieldStyle(formfield)
        formfield:notifyFieldChanged()
    end
end
function dictionaryField.getElement(name,value,options)
    local formField = {}
    local keyValidator = options.keyValidator or function(v)
        return type(v)=="string"
    end
    local valueValidator = options.valueValidator or function(v)
        return type(v)=="string"
    end
    local keyWarning = options.keyWarning or function (v)
        return true
    end
    local valueWarning = options.valueWarning or function (v)
        return true
    end
    local keyDisplayTransformer = options.keyDisplayTransformer or function (v)
        return v
    end
    local valueDisplayTransformer = options.keyDisplayTransformer or function (v)
        return v
    end
    local keyTransformer = options.keyTransformer or function (v)
        return v
    end
    local valueTransformer = options.valueTransformer or function (v)
        return v
    end

    local minWidth = options.minWidth or options.width or 160
    local maxWidth = options.maxWidth or options.width or 160

    local keyMinWidth = options.keyMinWidth or options.keyWidth or 80
    local keyMaxWidth = options.keyMaxWidth or options.keyWidth or 80
    local valueMinWidth = options.valueMinWidth or options.valueWidth or 80
    local valueMaxWidth = options.valueMaxWidth or options.valueWidth or 80

    local label = uiElements.label(options.displayName or name)
    formField.keys = {}
    formField.values = {}
    formField.rows = {}
    local keys = {}
    local values = {}
    local function makeRow(newKey,newValue,idx)
        local ktext = keyDisplayTransformer(newKey)
        table.insert(formField.keys,uiElements.field(ktext,keyChanged(formField,idx)):with({
            minWidth = keyMinWidth,
            maxWidth = keyMaxWidth
        }))
        table.insert(keys,ktext)
        local vtext = valueDisplayTransformer(newValue)
        table.insert(formField.values,uiElements.field(vtext,valueChanged(formField,idx)):with({
            minWidth = valueMinWidth,
            maxWidth = valueMaxWidth
        }))
        table.insert(values,vtext)
        local label = uiElements.label(":")
        local row = uiElements.row({formField.keys[idx],label,formField.values[idx]})
        table.insert(formField.rows,row)
    end
    for idx=1,#value.keys,1 do
        makeRow(value.keys[idx],value.values[idx],idx)
    end
    local field = uiElements.field(getLabelString(keys,values),function () end):with({
        minWidth = minWidth,
        maxWidth = maxWidth
    })
    local fieldWithConext = contextMenu.addContextMenu(field,
        function ()
            return expandableGrid.getGrid(formField.rows,4,{minWidth=keyMinWidth,maxWidth=keyMaxWidth},
                function ()
                    table.insert(value.keys,"")
                    table.insert(value.values,"")
                    makeRow("","",#value.keys)
                    local kchanged = keyChanged(formField,#keys)
                    kchanged(formField.keys[#value.keys],"")
                    local vchanged = valueChanged(formField,#keys)
                    vchanged(formField.values[#value.keys],"")
                    return formField.rows[#value.keys]
                end,
                function (idx)
                    table.remove(value.keys)
                    table.remove(value.values)
                    table.remove(formField.currentValue.keys)
                    table.remove(formField.currentValue.values)
                    updateFieldStyle(formField)
                end
            )
        end,
        {
            shouldShowMenu = function () return true end,
            mode = "focused"
        }
    )
    field:setPlaceholder("")
    if options.tooltipText then
        label.interactive = 1
        label.tooltipText = options.tooltipText
    end
    label.centerVertically = true

    formField.label = label
    formField.field = field
    formField.name = name
    formField.initialValue = value
    formField.currentValue = value
    formField.validVisuals = {
        keys = {},
        values = {}
    }
    formField.warnVisuals = {
        keys = {},
        values = {}
    }
    for i,v in ipairs(keys) do
        formField.validVisuals.keys[i] = true
        formField.validVisuals.values[i] = true
        formField.warnVisuals.keys[i] = true
        formField.warnVisuals.values[i] = true
    end
    formField.overValidVisuals = true
    formField.overWarnVisuals = true
    formField.keyTransformer = keyTransformer
    formField.valueTransformer = valueTransformer
    formField.keyValidator = keyValidator
    formField.valueValidator = valueValidator
    formField.keyDisplayTransformer = keyDisplayTransformer
    formField.valueDisplayTransformer = valueDisplayTransformer
    formField.keyWarning = keyWarning
    formField.valueWarning = valueWarning
    formField.currentText = value
    formField.width = 2
    formField.elements = {
        label,fieldWithConext
    }

    return setmetatable(formField,dictionaryField._MT)
end


return dictionaryField