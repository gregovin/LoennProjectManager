local mods = require("mods")
local fileSystem = require("utils.filesystem")
local utils = require("utils")
local logging = require("logging")
local pluginLoader = require("plugin_loader")
local configs = require("configs")
local settings= mods.requireFromPlugin("libraries.settings")
local filehelper = mods.requireFromPlugin("libraries.filesystemHelper")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local xmlHandler = require("lib.xml2lua.xmlhandler.tree")
local xml2lua = require("lib.xml2lua.xml2lua")
local xmlWriter = mods.requireFromPlugin("libraries.xmlWriter")
local packer = {
    entry = "xmls",
    overides = true
}


---@class XMLclaim
---@field claim string the xml name
---@field mapTarget string[] what indecies in `sideStruct.decode(mapcoder.decodeFile(mapLocation))` needs to be changed when the xml is moved
---@field pfunc (fun(string):string)|nil a function that takes the relative path to the xml file from the mod root and returns the desired string to write to the map file. Defaults to the identity

local xmlHandlers = {} ---@type {[string]: XMLclaim}

---@class XMLReparser
---@field kind string what xml to target
---@field apply fun(xml: table,umap: {[string]:string}, oldcamp: string|integer,content_map: {[string|integer]: CMAP}) a function to run on the parsed xml that mutates it in place

local xmlReparsers = {} ---@type {[string|integer]: fun(xml: table,umap: {[string]: string},oldcamp: string|integer,content_map: {[string|integer]: CMAP})[]}
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
---Mutate xmls
---@param kind string|integer
---@param newpath string
---@param umap {[string]:string}
---@param oldcamp string|integer
---@param content_map {[string|integer]: CMAP}
local function applyreparsers(kind, newpath, umap,oldcamp,content_map)
    local xml = utils.stripByteOrderMark(utils.readAll(newpath))
    local xhandler = xmlHandler:new()
    local parser = xml2lua.parser(xhandler)
    parser:parse(xml)
    
    for _,v in ipairs(xmlReparsers[kind]) do
        v(xhandler.root.Data,umap, oldcamp,content_map)
    end
    for _,v in ipairs(xmlReparsers[0]) do
        v(xhandler.root.Data,umap, oldcamp,content_map)
    end
    local target, msg = io.open(newpath, "w")
    if not target then return end
    local outstring = xmlWriter.toXml(xhandler.root)
    local xmlFixPattern = "()<([^/%s>]*)([^/>]*)>%s*<([^/%s>]*)>([^<]*)</%4>()"
    local s, fst, attrs, snd, conts, e = string.match(outstring, xmlFixPattern)

    while fst do
        if fst == snd or string.find(attrs, "[^\"]" .. string.gsub(snd, '%W', '%%%1') .. "[^\"]") then
            s = s + 1
            s, fst, attrs, snd, conts, e = string.match(outstring, xmlFixPattern, s)
        else
            outstring = string.sub(outstring, 1, s - 1) ..
                "<" .. fst .. attrs .. " " .. snd .. "=\"" .. conts .. "\">" .. string.sub(outstring, e)
            s, fst, attrs, snd, conts, e = string.match(outstring, xmlFixPattern)
        end
    end
    outstring=string.gsub(outstring,"<([^/%s>]*)([^/>]*)></%1>","<%1%2/>")
    target:write(outstring)
    target:close()
end
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
        local cmap = content_map[settings.get("campaigns",{0},"recentProjectInfo")[1]]
        local newuser
        for _,v in pairs(umap) do
            newuser=v
        end
        local target_path = fileSystem.joinpath(topdir,"xmls",newuser,cmap.newName)
        local newpath=fileSystem.joinpath(target_path,target)
        fileSystem.rename(fileSystem.joinpath(topdir,target),newpath)
        local next = fileSystem.stripExtension(target)
        if xmlReparsers[next] or xmlReparsers[0] then
            applyreparsers(next, newpath, umap,settings.get("campaigns",{0},"recentProjectInfo")[1], content_map)
        end
        return --enforce being done
    elseif not fileSystem.isDirectory(topdir,target) then
        return
    end
    if target=="xmls" or target=="xml" then
        
    elseif umap[target] then

    elseif content_map[target] then
    
    end
end

---@param h PHook
---@---@return PHook?
function packer.addHook(h)
    local c = h.content --[[@as XMLReparser]]
    xmlReparsers[c.kind] = xmlReparsers[c.kind] or {}
    table.insert(xmlReparsers[c.kind], c.apply)
end
packer.hooks={}---@type PHook[]

function packer.init()
    pluginLoader.loadPlugins(mods.findPlugins(fileSystem.joinpath("repackers", "Graphics", "xml")), nil, xcallback, false)
    for _,v in pairs(xmlHandlers) do
        local pf =v.pfunc or function (pth)
            return pth
        end ---@type fun(p: string): string
        table.insert(packer.hooks,{
            parents = 1,
            target = {"maps"},
            ---Map Xml Hook
            ---@param mapt table
            ---@param umap {[string]: string}
            ---@param oldcamp string?
            ---@param oldmap string
            ---@param mp {[string|integer]: CMAP}
            content = function (mapt, umap, oldcamp, oldmap, mp)
                local target = mapt ---@type any
                for _,t in ipairs(v.mapTarget) do
                    target = (target and target[t]) or nil
                end
                if type(target) == "string" then
                    local spth = fileSystem.splitpath(target) ---@type string[]
                    if spth[#spth] ~= v.claim ..".xml" then
                        return
                    end
                    local npath = {}
                    local sawuname=false
                    for _,s in spth do
                        if umap[s] and not sawuname then
                            table.insert(npath,umap[s])
                            sawuname=true
                        elseif s==oldcamp then
                            table.insert(npath,mp[s].newName)
                        elseif mp[oldcamp].mapMap[s] then
                            table.insert(npath,mp[oldcamp].mapMap[s])
                        else
                            table.insert(npath,s)
                        end
                    end
                    metadataHandler.setNested(mapt,v.mapTarget,pf(fileSystem.joinpath(unpack(npath))))
                end
            end
        })
    end
end
return packer
