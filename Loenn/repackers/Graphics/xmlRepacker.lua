local mods = require("mods")
local fileSystem = require("utils.filesystem")
local utils = require("utils")
local logging = require("logging")
local pluginLoader = require("plugin_loader")
local configs = require("configs")
local settings= mods.requireFromPlugin("libraries.settings")
local filehelper = mods.requireFromPlugin("libraries.filesystemHelper")

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


local xmlTracker = {} ---@type {[string]: string}  a map from previous paths to new paths (relative to Graphics)

---@param target string
---@param umap {[string]: string}
---@param content_map {[string|integer]: CMAP}
---@param topdir string
function packer.apply(target, umap, content_map, topdir) ---Apply this packer
    --our target structure is xmls/username/campaignname/file
    --however this may be different in reality
    if fileSystem.isFile(fileSystem.joinpath(topdir, target)) and xmlHandlers[fileSystem.stripExtension(target)] and fileSystem.fileExtension(target)=="xml" then --in this case the top level dir an xml file that we can handle
        
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
        local un_target = filehelper.getUniqueName(target_path, target)
        fileSystem.rename(fileSystem.joinpath(topdir,target),fileSystem.joinpath(target_path,un_target))
        xmlTracker[target]=fileSystem.joinpath(target_path,un_target)
        return --enforce being done
    elseif not (umap[target] or content_map[target] or target=="xml") or not fileSystem.isDirectory(topdir,target) then
        return
    end
    --look for files anywhere in xmls/uname/cname/
    local potential_xmls = filehelper.findRecFiles(fileSystem.joinpath(target),2)
    local definite_targets = $(potential_xmls):filter(function (_idx, pth)
        return xmlHandlers[fileSystem.stripExtension(fileSystem.filename(pth))] and fileSystem.fileExtension(pth)=="xml"
    end)()
    
end

---@param h PHook
---@return PHook?
function packer.addHook(h)
    local c = h.content --[[@as XMLReparser]]
    xmlReparsers[c.kind] = xmlReparsers[c.kind] or {}
    table.insert(xmlReparsers[c.kind], c.apply)
end
function packer.init()
    pluginLoader.loadPlugins(mods.findPlugins(fileSystem.joinpath("repackers", "Graphics", "xml")), nil, xcallback, false)
end
return packer
