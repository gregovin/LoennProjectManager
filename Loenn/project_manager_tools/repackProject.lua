local mods = require("mods")
local warnings = mods.requireFromPlugin("libraries.warningGenerator")
local settings = mods.requireFromPlugin("libraries.settings")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local pLoader = mods.requireFromPlugin("libraries.projectLoader")
local state = require("loaded_state")
local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

local postscript = {
    name = "repackProject",
    displayName = "Repackage Project",
    tooltip = "Change the folders used by the current project",
    layer = "project",
    --paramaters are dymacally generated
}
function postscript.prerun()
    local pdetails = pUtils.getProjectDetails()
    local filename = { fieldType = "loennProjectManager.fileName" }
    local mapFilename = {
        fieldType = "loennProjectManager.fileName",
        ismap = true
    }
    local cmaps = {
        fieldType = "loennProjectManager.customList",
        elementOptions = filename,
    }
    postscript.parameters = {}
    postscript.tooltips = {}
    postscript.fieldInformation = {}
    postscript.fieldOrder = {}
    local fname = state.filename
    if pdetails.name and pdetails.username and pdetails.campaign and pdetails.map and fileSystem.joinpath(modsDir, pdetails.name,
            "Maps", pdetails.username, pdetails.campaign, pdetails.map .. ".bin") == fname then
        postscript.parameters.modName = pdetails.name
        postscript.tooltips.modName =
        "The identifier for mod. This will be the top level folder your mod will be saved in. It should be unique.\n Must be a valid portable filename. \nFor many mods it makes sense for this to be the same as or similar your Map Name."
        postscript.fieldInformation.modName = filename
        table.insert(postscript.fieldOrder, "modName")
        postscript.parameters.username = pdetails.username
        postscript.tooltips.username = "Your username. Must be a valid portable filename"
        postscript.fieldInformation.username = filename
        table.insert(postscript.fieldOrder, "username")
        local campaigns = settings.get("campaigns", {}, "recentProjectInfo")
        for _, v in ipairs(campaigns) do
            local sv = v
            if v == "username" or v == "modName" then
                sv = v .. " campaign"
            end
            postscript.parameters[sv] = v
            postscript.tooltips[sv] = "What to repack campaign " .. v .. " as"
            postscript.fieldInformation[sv] = filename
            table.insert(postscript.fieldOrder, sv)
            local campaignDir = fileSystem.joinpath(modsDir, pdetails.name, "Maps", pdetails.username, v)
            local mapMap = {}
            local ms = $(pUtils.list_dir(campaignDir)):filter(function (i,item)
                return fileSystem.fileExtension(item) == 'bin'
            end)()
            if #ms > 1 then
                postscript.tooltips[v .. " maps"] = "What to repack " .. v .. "'s maps as"
                postscript.fieldInformation[v .. " maps"] = cmaps


                for _, m in ipairs(ms) do
                    local mName = fileSystem.stripExtension(m)
                    mapMap[mName] = mName
                end
                postscript.parameters[v .. " maps"] = mapMap
                table.insert(postscript.fieldOrder, v .. " maps")
            elseif #ms == 1 then
                local mname = fileSystem.stripExtension(ms[1])
                postscript.parameters[v .. " maps"] = mname
                postscript.tooltips[v .. " maps"] = "What to rename map " .. mname .. " as"
                postscript.fieldInformation[v .. " maps"] = table.shallowcopy(mapFilename)
                postscript.fieldInformation[v .. " maps"].displayName = v.."/"..mname
                table.insert(postscript.fieldOrder, v .. " maps")
            end
        end
    else
        if not fname then return end
        local rpth = pUtils.pathDiff(modsDir, fname)
        local srelpath = fileSystem.splitpath(rpth)
        --assume the last element of srelpath is the map name, everything else is as normal
        local mapname = fileSystem.stripExtension(table.remove(srelpath))
        --srelpath = modName?, "Maps"?, userName?, campaignName?
        postscript.parameters.modName = srelpath[1] or ""
        postscript.tooltips.modName =
        "The identifier for mod. This will be the top level folder your mod will be saved in. It should be unique.\n Must be a valid portable filename. \nFor many mods it makes sense for this to be the same as or similar your Map Name."
        postscript.fieldInformation.modName = filename
        table.insert(postscript.fieldOrder, "modName")
        postscript.parameters.username = srelpath[3] or settings.get("username", "")
        postscript.tooltips.username = "Your username. Must be a valid portable filename"
        postscript.fieldInformation.username = filename
        table.insert(postscript.fieldOrder, "username")
        if srelpath[4] then
            --in this case there is at least one campaign
            local ctarg = fileSystem.joinpath(modsDir, srelpath[1], srelpath[2], srelpath[3])
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
                    table.insert(postscript.fieldOrder, scamp)
                    local mapMap = {}
                    postscript.tooltips[camp .. " maps"] = "What to repack " .. camp .. "'s maps as"
                    postscript.fieldInformation[camp .. " maps"] = cmaps
                    for _, m in ipairs(pUtils.list_dir(campdir)) do
                        local mName = fileSystem.stripExtension(m)
                        mapMap[mName] = mName
                    end
                    postscript.parameters[camp .. " maps"] = mapMap
                    table.insert(postscript.fieldOrder, camp .. "maps")
                elseif fileSystem.fileExtension(camp) == "bin" then
                    table.insert(loose_maps, fileSystem.stripExtension(camp))
                end
            end
            if #loose_maps > 0 then
                postscript.parameters["unknown campaign"] = ""
                postscript.tooltips["unknown campaign"] = "What campaign to create for the badly structured maps"
                postscript.fieldInformation["unknown campaign"] = filename
                table.insert(postscript.fieldOrder, "unknown campaign")
                local mapMap = {}
                for _, m in ipairs(loose_maps) do
                    mapMap[m] = m
                end
                postscript.parameters["unknown campaign maps"] = mapMap
                postscript.tooltips["unknown campaign maps"] = "How to rename poorly structured maps"
                postscript.fieldInformation["unknown campaign maps"] = cmaps
                table.insert(postscript.fieldOrder, "unknown campaign maps")
            end
        elseif #srelpath > 0 then
            postscript.parameters["unknown campaign"] = ""
            postscript.tooltips["unknown campaign"] = "What campaign to create for the badly structured maps"
            postscript.fieldInformation["unknown campaign"] = filename
            local mdir = modsDir
            for _, p in ipairs(srelpath) do
                mdir = fileSystem.joinpath(mdir, p)
            end
            local maps = pUtils.list_dir(mdir)
            if #maps > 1 then
                postscript.parameters["unstructued maps"] = {}
                postscript.tooltips["unstructured maps"] = "What to rename unstructured maps"
                postscript.fieldInformation["unstructured maps"] = cmaps
                table.insert(postscript.fieldOrder, "unstructued maps")
                for _, mf in ipairs(maps) do
                    if fileSystem.fileExtension(mf) == "bin" then
                        local mmane = fileSystem.stripExtension(mf)
                        postscript.parameters["unstructued maps"][mmane] = mmane
                    end
                end
            else
                local smapname = mapname
                if postscript.parameters[smapname] then
                    smapname = smapname .. " map"
                end
                postscript.parameters[smapname] = mapname
                postscript.tooltips[smapname] = "What to rename the loaded map"
                postscript.fieldInformation[smapname] = mapFilename
            end
        else
            postscript.parameters.newCampaign = ""
            postscript.tooltips.newCampaign = "What campaign to create for the unstructured loaded map"
            postscript.fieldInformation.newCampaign = filename
            local smapname = mapname
            if postscript.parameters[smapname] then
                smapname = smapname .. " map"
            end
            postscript.parameters[smapname] = mapname
            postscript.tooltips[smapname] = "What to rename the loaded map"
            postscript.fieldInformation[smapname] = mapFilename
        end
    end
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
