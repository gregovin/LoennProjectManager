local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local utils = require("utils")
local fileSystem = require("utils.filesystem")
local logging = require("logging")
local pluginLoader = require("plugin_loader")
local configs = require("configs")

local packer = {
    entry = "Graphics",
    overides = true,
}
local graphicsHandlers = {} ---@type {[string]: Packer}
local function gcallback(filename)
    local pathNoExt = fileSystem.stripExtension(filename)
    local fileNameNoExt = fileSystem.filename(pathNoExt)
    local mod = utils.humanizeVariableName(string.sub(filename, 2, string.find(filename, "/") - 2)):gsub(" Zip", "")
    local handler = utils.rerequire(pathNoExt) --[[@as Packer]]
    handler.__mod = mod
    if not (graphicsHandlers[handler.entry] and graphicsHandlers[handler.entry].overides) then
        graphicsHandlers[handler.entry] = handler
        if configs.debug.logPluginLoading then
            logging.info("Loaded graphical remapper " .. handler.entry .. " [" .. mod .. "]")
        end
    else
        if configs.debug.logPluginLoading then
            logging.info("Graphical remapper " .. handler.entry .. " [" .. mod .. "] was overriden")
        end
    end
end
pluginLoader.loadPlugins(mods.findPlugins(fileSystem.joinpath("repackers", "Graphics")), nil, gcallback, false)
function packer.apply(modname, umap, content_map, topdir)
    local gpath = fileSystem.joinpath(topdir, "Graphics")
    for _, v in ipairs(pUtils.list_dir(gpath)) do
        if graphicsHandlers[v] then
            graphicsHandlers[v].apply(v, umap, content_map, gpath)
        else
            graphicsHandlers["xml"].apply(v, umap, content_map, gpath)
        end
    end
end

---Hook nonsense time
---@param h PHook
---@return PHook?
function packer.addHook(h)
    if h.parents > 0 then
        h.parents -= 1
        return h
    end
    if #h.target > 0 then
        local tv = table.remove(h.target, 1)
        if graphicsHandlers[tv] then
            graphicsHandlers[tv].addHook(h)
        end
    end
end

for _, v in pairs(graphicsHandlers) do
    if v.hooks then
        local outhooks = {}
        for _, h in ipairs(v.hooks) do
            local co = graphicsHandlers.addHook(h)
            if co then table.insert(outhooks, co) end
        end
        if #outhooks > 0 then
            packer.hooks = packer.hooks or {}
            for i = 1, #outhooks do
                packer.hooks[#packer.hooks + 1] = outhooks[i]
            end
        end
    end
end
return packer ---@type Packer
