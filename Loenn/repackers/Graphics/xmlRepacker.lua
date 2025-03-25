local mods = require("mods")
local fileSystem = require("utils.filesystem")
local utils = require("utils")
local logging = require("logging")
local pluginLoader = require("plugin_loader")
local configs = require("configs")
local settings= mods.requireFromPlugin("libraries.settings")

local packer = {
    entry = "xmls",
    overides = true
}


---@class XMLclaim
---@field claim string the xml name
---@field mapTarget string what index in `sideStruct.decode(mapcoder.decodeFile(mapLocation))` needs to be changed when the xml is moved
---@field pfunc (fun(string):string)|nil a function that takes the path to the xml file and returns the desired string to write to the map file. Defaults to the relative path from the mod root

local xmlHandlers = {} ---@type {[string]: XMLclaim}

---@class XMLReparser
---@field kind string what xml to target
---@field apply fun(table): table a function to run on the parsed xml that returns the new value.

local xmlReparsers = {} ---@type {[string]: (fun(table): table)[]}
local function xcallback(filename)
    local pathNoExt = fileSystem.stripExtension(filename)
    local fileNameNoExt = fileSystem.filename(pathNoExt)
    local mod = utils.humanizeVariableName(string.sub(filename, 2, string.find(filename, "/") - 2)):gsub(" Zip", "")
    local handler = utils.rerequire(pathNoExt) ---@type XMLclaim[]
    for _, v in ipairs(handler) do
        xmlHandlers[v.claim] = v
    end
    if configs.debug.logPluginLoading then
        logging.info("Loaded xml claims " .. fileNameNoExt .. " [" .. mod .. "]")
    end
end
pluginLoader.loadPlugins(mods.findPlugins(fileSystem.joinpath("repackers", "Graphics", "xml")), nil, xcallback, false)

local xmlTracker = {} ---@type {[string],string}  a map from previous paths to new paths (relative to Graphics)

---@param target string
---@param umap {[string]: string}
---@param content_map {[string|integer]: CMAP}
---@param topdir string
function packer.apply(target, umap, content_map, topdir) ---Apply this packer
    --our target structure is xmls/username/campaignname/file
    --however this may be different in reality
    if fileSystem.isFile(fileSystem.joinpath(topdir, target)) and xmlHandlers[fileSystem.stripExtension(target)] then --in this case the top level dir an xml file that we can handle
        
        if #settings.get("campaigns",{},"recentProjectInfo") ~=1 then
            return --if there is more than one campaign, give up
        end
        --make sure we have a path for the loose xml
        local cmap = content_map[settings.get("campaigns",{},"recentProjectInfo")[1]]
        local newuser
        for _,v in pairs(umap) do
            newuser=v
        end
        local target_path = fileSystem.joinpath(topdir,"xmls",newuser,cmap.newName)
        fileSystem.rename(fileSystem.joinpath(topdir,target),fileSystem.joinpath(target_path,target))
        xmlTracker[target]=fileSystem.joinpath(target_path,target)
    end
end

---@param h PHook
---@return PHook?
function packer.addHook(h)
    local c = h.content --[[@as XMLReparser]]
    xmlReparsers[c.kind] = xmlReparsers[c.kind] or {}
    table.insert(xmlReparsers[c.kind], c.apply)
end

return packer
