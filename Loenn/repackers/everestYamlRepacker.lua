local mods = require("mods")
local fileSystem = require("utils.filesystem")
local yaml = require("lib.yaml")
local pluginLoader = require("plugin_loader")
local logging = require("logging")
local configs = require("configs")

local utils = require("utils")
---@class Packer
---@field entry string a one element name that refers to the desired path of the item or folder that must be changed
---@field overides boolean? gaurntees that the loaded packer for everest.yaml has overides=true when true
---@field __mod string? the handler's source mod
local packer = {
    entry = "everest.yaml",
    overides = true,
}
local eyml_filenames = mods.findPlugins(fileSystem.joinpath("repackers", "everestYaml"))
---@class YamlHandler
---@field __mod string the handler's source mod
---@field name string  the handler name
---@field overides boolean? gaurntees that the loaded packer for this name has overides=true when true
---@field apply fun(yamlConts: table,modname: string,umap: {[string]: string},content_map: {[string|integer]: CMAP}): table A function that takes the parsed yaml and the new info and returns the corrected yaml. These may be called in any order

local eyml_handers = {} ---@type {[string]: YamlHandler}
local function flcallback(filename)
    local pathNoExt = fileSystem.stripExtension(filename)
    local fileNameNoExt = fileSystem.filename(pathNoExt)
    local mod = utils.humanizeVariableName(string.sub(filename, 2, string.find(filename, "/") - 2)):gsub(" Zip", "")
    local handler = utils.rerequire(pathNoExt) --[[@as YamlHandler]]
    handler.__mod = mod
    if not (eyml_handers[handler.name] and eyml_handers[handler.name].overides) then
        eyml_handers[handler.name] = handler
        if configs.debug.logPluginLoading then
            logging.info("Loaded everest.yaml remapper '" .. handler.name or
                fileNameNoExt .. "' [" .. mod .. "] " .. " from: " .. mod)
        end
    else
        if configs.debug.logPluginLoading then
            logging.info("Everest.yaml remapper '" .. handler.name or
                fileNameNoExt .. "' [" .. mod .. "] from " .. mod .. " overriden")
        end
    end
end
pluginLoader.loadPlugins(eyml_filenames, nil, flcallback, false)
local target_pattern = ""
---@class CMAP
---@field newName string the new campaign name
---@field mapMap {[string]: string} a map from current map names in this campaign to new map names
---Apply this repacker
---@param modname string the name of the mod
---@param umap {[string]: string} a single element table with umap[currentUsername]=newUsername
---@param content_map {[string|integer]: CMAP}
---@param topdir string the path to the top level mod dir
function packer.apply(modname, umap, content_map, topdir)
    local ymlpth = fileSystem.joinpath(topdir, "everest.yaml")
    if not fileSystem.isFile(ymlpth) then return end
    local content = utils.readAll(ymlpth)
    local ymlconts = yaml.read(utils.stripByteOrderMark(content))
    ymlconts.name = modname
    for _, h in pairs(eyml_handers) do
        ymlconts = h.apply(ymlconts, modname, umap, content_map)
    end
    yaml.write(ymlpth, ymlconts)
end

return packer
