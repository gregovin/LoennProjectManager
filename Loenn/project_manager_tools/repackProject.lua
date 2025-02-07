local mods = require("mods")
local settings = mods.requireFromPlugin("libraries.settings")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local pLoader = mods.requireFromPlugin("libraries.projectLoader")
local state = require("loaded_state")
local fileSystem = require("utils.filesystem")
local utils = require("utils")
local configs = require("configs")
local pluginLoader = require("plugin_loader")
local fileLocations = require("file_locations")
local logging = require("logging")
local notifications = require("ui.notification")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")


local repackers ---@type {[string]: Packer}
local function rcallback(filename)
    local pathNoExt = fileSystem.stripExtension(filename)
    local mod = utils.humanizeVariableName(string.sub(filename, 2, string.find(filename, "/") - 2)):gsub(" Zip", "")
    local handler = utils.rerequire(pathNoExt) --[[@as Packer]]
    handler.__mod = mod
    if not (repackers[handler.entry] and repackers[handler.entry].overides) then
        repackers[handler.entry] = handler
        if configs.debug.logPluginLoading then
            logging.info("Loaded remapper '" .. handler.entry .. "' [" .. mod .. "]")
        end
    elseif configs.debug.logPluginLoading then
        logging.info("Overrode remapper '" .. handler.entry .. "' [" .. mod .. "]")
    end
end

local postscript = {
    name = "repackProject",
    displayName = "Repackage Project",
    tooltip = "Change the folders used by the current project",
    layer = "project",
    verb = "apply"
    --paramaters are dymacally generated
}
function postscript.prerun()
    local pdetails = pUtils.getProjectDetails()
    local filename = { fieldType = "loennProjectManager.fileName" }
    local cmaps = {
        fieldType = "loennProjectManager.customList",
        elementOptions = filename,
    }
    postscript.parameters = {}
    postscript.tooltips = {
        modName =
        "The identifier for mod. This will be the top level folder your mod will be saved in. It should be unique.\n Must be a valid portable filename. \nFor many mods it makes sense for this to be the same as or similar your Map Name.",
        username = "Your username. Must be a valid portable filename"
    }
    postscript.fieldInformation = {
        modName = filename,
        username = filename
    }
    --track additional info to access at runtime
    postscript.additionalInfo  = {
        modName = {},
        username = {}
    }
    postscript.fieldOrder = {"modName","username"}
    local fname = state.filename
    --dynamiically generating a script is fine :)
    --we know campaign names are unique among themselves
    if not fname then error("no map open") end
    local rpth = pUtils.pathDiff(modsDir, fname)
    local srelpath = fileSystem.splitpath(rpth)
    --assume the last element of srelpath is the map name, everything else is as normal
    local mapname = fileSystem.stripExtension(table.remove(srelpath))
    --srelpath = modName?, "Maps"?, userName?, campaignName?
    postscript.parameters.modName = srelpath[1] or ""
    postscript.parameters.username = srelpath[3] or settings.get("username", "")

    if srelpath[4] then
        --in this case there is at least one campaign
        --so look in the folder where the campaigns are
        local ctarg = fileSystem.joinpath(modsDir, srelpath[1], srelpath[2], srelpath[3])
        --we're also not going to assume these are placed sanely
        local loose_maps = {}
        for _, camp in ipairs(pUtils.list_dir(ctarg)) do
            local campdir = fileSystem.joinpath(ctarg, camp)
            if fileSystem.isDirectory(campdir) then
                local scamp = camp
                if camp == "username" or camp == "modName" then
                    scamp = camp .. " campaign"
                end
                postscript.parameters[scamp] = camp
                postscript.tooltips[scamp] = "What to repack campaign " .. camp .. " as"
                postscript.fieldInformation[scamp] = filename
                postscript.additionalInfo[scamp] = {isCampaign = true, reffersTo = camp}
                table.insert(postscript.fieldOrder, scamp)
                local mls = $(pUtils.list_dir(campdir)):filter(function (i,item)
                    return fileSystem.fileExtension(item) == 'bin'
                end)()
                if #mls > 1 then
                    local mapMap = {}
                    postscript.tooltips[camp .. " maps"] = "What to repack " .. camp .. "'s maps as"
                    postscript.fieldInformation[camp .. " maps"] = cmaps
                    for _, m in ipairs(pUtils.list_dir(campdir)) do
                        local mName = fileSystem.stripExtension(m)
                        mapMap[mName] = mName
                    end
                    postscript.parameters[camp .. " maps"] = mapMap
                    postscript.additionalInfo[camp .. " maps"] = {multiple = true, inCampaign = camp}
                    table.insert(postscript.fieldOrder, camp .. "maps")
                elseif #mls==1 then
                    local mname = fileSystem.stripExtension(mls[1])
                    postscript.parameters[camp .. " maps"] = mname
                    postscript.tooltips[camp .. " maps"] = "What to rename map " .. mname .. " as"
                    postscript.fieldInformation[camp .. " maps"] = table.shallowcopy(filename)
                    postscript.fieldInformation[camp .. " maps"].displayName = camp.."/"..mname
                    postscript.additionalInfo[camp.." maps"] = {multiple = false, inCampaign = camp, reffersTo = mname}
                    table.insert(postscript.fieldOrder, camp .. " maps")
                end
                
            elseif fileSystem.fileExtension(camp) == "bin" then
                table.insert(loose_maps, fileSystem.stripExtension(camp))
            end
        end
        if #loose_maps > 0 then
            --unknown campaign gets sentinel key 0
            postscript.parameters[0] = ""
            postscript.tooltips[0] = "What campaign to create for the badly structured maps"
            postscript.fieldInformation[0] = table.shallowcopy(filename)
            postscript.fieldInformation[0].displayName = "unknown campaign"
            postscript.additionalInfo[0] = {isCampaign = true}
            table.insert(postscript.fieldOrder, 0)
            if #loose_maps>1 then
                local mapMap = {}
                for _, m in ipairs(loose_maps) do
                    mapMap[m] = m
                end
                --and its maps get sentinel key -1
                postscript.parameters[-1] = mapMap
                postscript.tooltips[-1] = "How to rename poorly structured maps"
                postscript.fieldInformation[-1] = table.shallowcopy(cmaps)
                postscript.fieldInformation[-1].displayName = "unknown campaign maps"
                postscript.additionalInfo[-1] = {multiple = true}
                table.insert(postscript.fieldOrder, -1)
            else
                local mname = loose_maps[1]
                postscript.parameters[-1] = mname
                postscript.tooltips[-1] = "How to rename unstructured map "..mname
                postscript.fieldInformation[-1] = table.shallowcopy(filename)
                postscript.fieldInformation[-1].displayName = "Unknown Campaign/"..mname
                postscript.additionalInfo[-1] = {reffersTo = mname}
                table.insert(postscript.fieldOrder, -1)
            end
            
        end
    elseif #srelpath > 0 then
        postscript.parameters[0] = ""
        postscript.tooltips[0] = "What campaign to create for the badly structured maps"
        postscript.fieldInformation[0] = table.shallowcopy(filename)
        postscript.fieldInformation[0].displayName = "unknown campaign"
        postscript.additionalInfo[0] = {isCampaign=true}
        table.insert(postscript.fieldOrder, 0)
        local mdir = modsDir
        for _, p in ipairs(srelpath) do
            mdir = fileSystem.joinpath(mdir, p)
        end
        local maps = $(pUtils.list_dir(mdir)):filter(function (i,item)
                    return fileSystem.fileExtension(item) == 'bin'
                end)()
        if #maps > 1 then
            postscript.parameters[-1] = {}
            postscript.tooltips[-1] = "What to rename unstructured maps"
            postscript.fieldInformation[-1] = table.shallowcopy(cmaps)
            postscript.fieldInformation[-1].displayName = "unknown campaign maps"
            postscript.additionalInfo[-1] = {multiple=true}
            table.insert(postscript.fieldOrder, -1)
            for _, mf in ipairs(maps) do
                local mmane = fileSystem.stripExtension(mf)
                postscript.parameters[-1][mmane] = mmane
            end
        else
            postscript.parameters[-1] = mapname
            postscript.tooltips[-1] = "What to rename the loaded map"
            postscript.fieldInformation[-1] = table.shallowcopy(mapname)
            postscript.fieldInformation[-1].displayName = "unknownCampaign/"..mapname
            postscript.additionalInfo[-1] = {reffersTo = mapname}
            table.insert(postscript.fieldOrder, -1)
        end
    else
        postscript.parameters.newCampaign = ""
        postscript.tooltips.newCampaign = "What campaign to create for the unstructured loaded map"
        postscript.fieldInformation.newCampaign = filename
        postscript.additionalInfo.newCampaign = {isCampaign=true}
        table.insert(postscript.fieldOrder, "newCampaign")
        local smapname = mapname
        if postscript.parameters[smapname] then
            smapname = smapname .. " map"
        end
        postscript.parameters[smapname] = mapname
        postscript.tooltips[smapname] = "What to rename the loaded map"
        postscript.fieldInformation[smapname] = table.shallowcopy(filename)
        postscript.fieldInformation[smapname].displayName = "newCampaign/"..mapname
        postscript.additionalInfo[smapname] = {reffersTo = mapname}
        table.insert(postscript.fieldOrder,smapname)
    end
end
---@param args {modName: string, username: string, [string|integer]: string}
function postscript.run(args)
    if not repackers then
        repackers = {}
        pluginLoader.loadPlugins(mods.findPlugins("repackers"), nil, rcallback, false)
    end
    --this is where the fun begins
    --step 1: create new modDir if it's different
    local newModDir = fileSystem.joinpath(modsDir,args.modName) ---@type string
    if fileSystem.isDirectory(newModDir) and args.modName ~= postscript.parameters.modName then
        notifications.notify("Cannot change mod name to "..args.modName.." as it already exists")
        logging.warn("Cannot change mod name to "..args.modName.." as a mod with the same name already exists")
        return
    end
    --we'll use srelpath logic
    local fname = state.filename
    if not fname then error("no map open") end
    local rpth = pUtils.pathDiff(modsDir, fname)
    local srelpath = fileSystem.splitpath(rpth)
    --assume the last element of srelpath is the map name, everything else is as normal
    local mapname = fileSystem.stripExtension(table.remove(srelpath))
    

    if #srelpath > 0 then
        --rename the top folder
        fileSystem.rename(fileSystem.joinpath(modsDir, srelpath[0]),newModDir)
        local umap = {[postscript.parameters.username] = args.username} ---@type {[string]:string}
        local cmap = {} ---@type {[string|integer]: CMAP} 
        for k,v in pairs(args) do
            if postscript.additionalInfo[k].isCampaign then
                local cname = postscript.additionalInfo[k].reffersTo or 0 ---@type string|integer
                cmap[cname] = cmap[cname] or {}
                cmap[cname].newName = v
            elseif postscript.additionalInfo[k].reffersTo then
                local cname = postscript.additionalInfo[k].inCampaign or 0 ---@type string|integer
                cmap[cname] = cmap[cname] or {}
                cmap[cname].mapMap = cmap[cname].mapMap or 0
                local mname = postscript.additionalInfo[k].reffersTo ---@type string
                cmap[cname].mapMap[mname] = v
            elseif postscript.additionalInfo[k].multiple then
                local cname = postscript.additionalInfo[k].inCampaign or 0  ---@type string|integer
                cmap[cname] = cmap[cname] or {}
                cmap[cmap].mapMap = v
            end
        end
        for _, e in pUtils.list_dir(newModDir) do
            e = string.lower(e)
            if repackers[e] then
                repackers[e].apply(args.modName,umap,cmap,newModDir)
            end
        end
    else
        --in this case, we had a lone map
        local mfolder = fileSystem.joinpath(newModDir,"Maps",args.username,args.newCampaign)
        settings.set("username", args.username)
        settings.set("name", args.modName, "recentProjectInfo")
        settings.set("SelectedCampaign", args.newCampaign, "recentProjectInfo")
        settings.set("campaigns", {args.newCampaign}, "recentProjectInfo")
        fileSystem.mkpath(mfolder)
        local newmapname
        for k,v in pairs(args) do
            if postscript.additionalInfo[k].reffersTo then
                newmapname = v
                break
            end
        end
        settings.set("maps", {newmapname}, "recentProjectInfo")
        settings.set("recentmap",newmapname, "recentProjectInfo")
        local mapLocal = fileSystem.joinpath(mfolder,newmapname .. ".bin")
        fileSystem.rename(fname, mapLocal)
        state.loadFile(mapLocal)
    end
    pLoader.clearMetadataCache()
    --unset script info so the garbage collector can eat it
    postscript.parameters = nil
    postscript.tooltips = nil
    postscript.fieldInformation = nil
    postscript.additionalInfo = nil
end
local script = {
    layer = "project",
    name = "repackProject",
    displayName = "Repackage Project",
    tooltip = "Change the folders used by the current project",
    parameters = {
        warningLabel = "",
        agree = false
    },
    tooltips = {
        
    },
    fieldInformation = {
        warningLabel = {
            fieldType = "loennProjectManager.label",
            labelName = "Repacking a project may invalidate any celeste saves for that project"
        },
        agree = {
            fieldType = "loennProjectManager.verificationCheckbox",
            labelName = "I understand and wish to proceed"
        }
    },
    fieldOrder = {"warningLabel","agree"},
    verb = "proceed",
    nextScript = postscript
}
return script
