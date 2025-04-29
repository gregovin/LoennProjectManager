local mods = require("mods")
local pluginLoader = require("plugin_loader")
local utils = require("utils")
local logging = require("logging")
local configs = require("configs")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local notifications = require("ui.notification")

local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local tempfolder = fileSystem.joinpath(fileLocations.getStorageDir(), "LPMTemp")

local script = {
    name = "ReskinEntity",
    displayName = "Reskin Entity",
    tooltip = "Reskin a reskinnable entity",
    paramaters = {
        entity = "Jump Through",
        edit=false
    },
    tooltips = {
        entity = "The entity to reskin",
        edit = "When checked the script will edit a currently reskinned entity instead of adding a new option, if at all possible"
    },
    fieldInformation = {
        entity = {
            fieldType = "string",
            options = {
            },
            editable=false
        }
    },
    nextScript = {
        name="ReskinEntity2",
        tooltip = "Reskin a reskinnable entity",
        verb= "Reskin"
    }
}
local reskinners = {} ---@type {[string]: Reskinner}
local function loadReskinner(filename)
    local modFolder = string.sub(filename, 2, string.find(filename, "/") - 2)
    local modName = utils.humanizeVariableName(modFolder):gsub(" Zip", "")
    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt
    handler.__mod = modName
    if configs.debug.logPluginLoading then
        logging.info("Loaded reskinner '" .. name .. "' [" .. modName .. "] " .. " from: " .. filename)
    end
    reskinners[name] = handler
    table.insert(script.fieldInformation.entity.options, name)
    return name
end
local function init()
    pluginLoader.loadPlugins(mods.findPlugins("reskinners"), nil, loadReskinner, false)
end


function script.prerun()
    if #reskinners==0 then
        init()
        for _,v in pairs(reskinners) do
            table.insert(script.fieldInformation.entity.options,v.name)            
        end
    end
end

function script.run(args)
    if not fileSystem.isDirectory(tempfolder) then
        fileSystem.mkpath(tempfolder)
    end
    local projectDetails = pUtils.getProjectDetails()
    --error if the state doesn't match
    projectLoader.assertStateValid(projectDetails)
    script.nextScript.displayName="Reskin "..args.entity
    script.nextScript.parameters = {}
    script.nextScript.tooltips = {}
    script.nextScript.fieldInformation = {}
    if reskinners[args.entity].allow_many then
        if reskinners[args.entity].multifile then
            local tdir = fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Gameplay")
            if reskinners[args.entity].append_mod_info then
                tdir = fileSystem.joinpath(tdir,reskinners[args.entity].target_dir,projectDetails.username,projectDetails.campaign) 
            else
                tdir = fileSystem.joinpath(tdir,projectDetails.username,projectDetails.campaign,reskinners[args.entity].target_dir)
            end
            local skns = pUtils.list_dir(tdir)
            table.sort(skns, function (a, b)
                return #a<#b or (#a==#b and a<b)
            end)
            local bns = {}
            for _,v in ipairs(skns) do
                local main, _ = string.match(fileSystem.filename(v),"^(.*)00.png$")
                if bns[#bns]~=main then
                    table.insert(bns, main)
                end
            end
            if args.edit and #bns>1 then

                script.nextScript.parameters.options = bns[1]
                script.nextScript.tooltips.options = "The reskin to edit"
                script.nextScript.fieldInformation.options ={
                    fieldType = "string",
                    options = bns,
                    editable=false
                }
                script.nextScript.verb = "select"
                script.nextScript.nextScript={
                    name = "Reskin3",
                    displayName = "Edit Reskin",
                    tooltip = "Edit the framedata for a specific reskin",
                    verb = "accept",
                    paramaters = {files = {}},
                    tooltips = {files = "the files to use"},
                    fieldInformation={files = {
                        fieldType = "loennProjectManager.filePathList",
                        extension = "png"
                    }}
                }
                function script.nextScript.run(args)
                    local fs = pUtils.list_dir(tdir)
                    for _,v in ipairs(fs) do
                        if string.find(v,args.options,1,true) then
                            table.insert(script.nextScript.nextScript.paramaters.files, fileSystem.joinpath(tdir,v))
                        end
                    end
                    script.nextScript.nextScript.bn = args.options
                end
                function script.nextScript.nextScript.run(args)
                    local bn = script.nextScript.nextScript.bn
                    local ts = fileSystem.joinpath(tempfolder,"reskin")
                    fileSystem.mkpath(ts)
                    for i,v in ipairs(args.files) do
                        local newname = bn .. string.format("%02d.png",i)
                        fileSystem.rename(v,fileSystem.joinpath(ts,newname))
                    end
                    for _,v in ipairs(pUtils.list_dir(ts)) do
                        fileSystem.rename(fileSystem.joinpath(ts,v),fileSystem.joinpath(tdir,v))
                    end
                end
            elseif args.edit and #bns==1 then
                script.nextScript.parameters.files = {}
                script.nextScript.tooltips.files ="the files to use"
                script.nextScript.verb = "accept"
                script.nextScript.fieldInformation={files = {
                    fieldType = "loennProjectManager.filePathList",
                    extension="png"
                }}
                local fs = pUtils.list_dir(tdir)
                for _,v in ipairs(fs) do
                    if string.find(v,bns[1],1,true) then
                        table.insert(script.nextScript.nextScript.paramaters.files, fileSystem.joinpath(tdir,v))
                    end
                end
                function script.nextScript.run(args)
                    local bn = bns[1]
                    local ts = fileSystem.joinpath(tempfolder,"reskin")
                    fileSystem.mkpath(ts)
                    for i,v in ipairs(args.files) do
                        local newname = bn .. string.format("%02d.png",i)
                        fileSystem.rename(v,fileSystem.joinpath(ts,newname))
                    end
                    for _,v in ipairs(pUtils.list_dir(ts)) do
                        fileSystem.rename(fileSystem.joinpath(ts,v),fileSystem.joinpath(tdir,v))
                    end
                end
            else
                script.nextScript.parameters.files = {}
                script.nextScript.parameters.baseName=""
                script.nextScript.tooltips.files ="The files to use"
                script.nextScript.tooltips.baseName="The name of the "..args.entity.." reskin"
                script.nextScript.fieldInformation={files={
                    fieldType="loennProjectManager.filePathList",
                    extension="png"
                    },
                    baseName = {
                        fieldType="loennProjectManager.fileName",
                        requireVal=true
                    }
                }
                script.nextScript.verb="Add"
                function script.nextScript.run(args)
                    local ts = fileSystem.joinpath(tempfolder,"reskin")
                    fileSystem.mkpath(ts)
                    for i,v in ipairs(args.files) do
                        fileSystem.rename(v,fileSystem.joinpath(ts, args.baseName..string.format("%02d.png",i)))
                    end
                    for _,v in pUtils.list_dir(ts) do
                        fileSystem.rename(fileSystem.joinpath(ts,v),tdir)
                    end
                end
            end
        else
            --allow_many=true,multifile=false
            
        end
    end
end

return script
