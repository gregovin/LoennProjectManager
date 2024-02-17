-- This code is based on the Loenn source code, which was created by the Everest Team under the MIT liscense
local ui = require("ui.main")
local uie = require("ui.elements.main")
local uiu = require("ui.utils")
local pUtils=require("mods").requireFromPlugin("libraries.projectUtils")

require("ui.elements.input")

uie.add("multiListItem",{
    base = "listItem",

    getSelected = function(self)
        local owner = self.owner or self.parent

        local getIsSelected = owner.getIsSelected
        if getIsSelected then
            return getIsSelected(owner, self)
        end

        if not owner.isMultiList then
            return self.selected
        end
        return owner.selected[self]
    end,

    toggleSelected = function(self)
        local owner = self.owner or self.parent
        owner.selected[self]= not owner.selected[self]
        self.selected = owner.selected[self]
    end,
    onClick = function(self, x, y, button)
        if self.enabled and button == 1 then
            local owner = self.owner or self.parent
            if owner.isMultiList then
                self:toggleSelected()
                owner:updateText()
                owner:runCallback()
            end
        end
    end
})
uie.add("multiselect", {
    base = "button",
    clip = false,
    interactive = 1,

    isMultiList = true,
    cbOnItemClick = true,

    init = function(self, list, cb)
        self._itemsCache = {}
        self.placeholder = list.placeholder
        uie.button.init(self, "")
        for i = 1, #list do
            self:getItemCached(list[i], i)
        end
        self.selected = self.placeholder or {}
        self.data = list
        self:addChild(uie.icon("ui:icons/drop"):with(uiu.at(0.999 + 1, 0.5 + 5)))
        self.cb = cb
        self.submenuParent = self
    end,

    getSelectedIndicies = function(self)
        local selected = self.selected
        local out = {}
        local children = self._itemsCache or self.children
        for i = 1, #children do
            local c = children[i]
            if selected[c] then
                out[i]=true
            end
        end

        return out
    end,

    setSelectedIndicies = function(self, value)
        local children = self._itemsCache or self.children
        for k,v in pairs(value) do
            self.selected[children[k]]=v
        end
    end,

    getSelectedData = function(self)
        local selected = self.selected
        local out = {}
        if not selected then
            return out
        end

        local children = self._itemsCache or self.children
        for i,c in ipairs(children) do
            if selected[c] then
                if c.data ~= nil then
                    out[c.data] =true
                else
                    out[c.text] = true
                end
            end
        end

        return out
    end,

    setSelectedData = function(self, values)
        local children = self._itemsCache or self.children
        for i,c in ipairs(children) do
            if c.data ~= nil then
                self.selected[c]=values[c.data]
            else
                self.selected[c]=values[c.text]
            end
        end
    end,
    getSelected = function(self)
        return self._selected
    end,

    setSelected = function(self, values, text)
        self._selected = values
        if text or text == nil then
            self.text = text or values or self.placeholder or ""
        end
    end,

    getItemCached = function(self, text, i)
        if not self._itemsCache then
            self._itemsCache = {}
        end
        local cache = self._itemsCache
        local item = cache[i]
        if item then
            local data
            if text and text.text and text.data ~= nil then
                data = text.data
                text = text.text
            end
            item.text = text
            item.data = data
        else
            item = uie.multiListItem(text):with({
                owner = self
            })
            cache[i] = item
        end
        return item
    end,
    updateText = function(self)
        local sel = $(pUtils.setAsList(self.selected)):map(k->k.text or k.data)()
        self.text=pUtils.listToString(sel)
    end,
    runCallback= function (self)
        self.cb(self,self:getSelectedData())
    end,
    getItem = function(self, i)
        return self:getItemCached(self.data[i], i)
    end,

    onClick = function(self, x, y, button)
        logging.info("Clicked")
        if self.enabled and button == 1 then
            local submenu = self.submenu
            local spawnNewMenu = true
            if submenu then
                -- Submenu might still exist if it was closed by clicking one of the options
                -- In which case we should spawn a new menu
                spawnNewMenu = not submenu.alive
                if submenu.alive then
                    self.updateText(self)
                    self.runCallback(self)
                end
                logging.info("despawn")
                submenu:removeSelf()
            end
            if spawnNewMenu then
                local submenuParent = self.submenuParent or self
                local submenuData = uiu.map(self.data, function(data, i)
                    local item = self:getItemCached(data, i)
                    item.width = false
                    item.height = false
                    item:layout()
                    return item
                end)
                x = submenuParent.screenX
                y = submenuParent.screenY + submenuParent.height + submenuParent.parent.style.spacing
                self.submenu = uie.menuItemSubmenu.spawn(submenuParent, x, y, submenuData)
            end
        end
    end
})
