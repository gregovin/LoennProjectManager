local mods = require("mods")
local tilesetHandler = mods.requireFromPlugin("libraries.tilesetHandler")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local notifications = require("ui.notification")
local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local safeDelete = mods.requireFromPlugin("libraries.safeDelete")
local logging = require("logging")
local history = require("history")
local snapshot = require("structs.snapshot")
local celesteRenderer = require("celeste_render")
local state = require("loaded_state")
local warningGenerator = mods.requireFromPlugin("libraries.warningGenerator")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")


local script={
    name = "deleteFgTileset",
    displayName = "Delete Fg Tileset",
    tooltip = "Remove a foreground tileset. Cannot remove templates or vannilla tilesets",
    verb="delete",
    parameters = {
        tileset = ""
    },
    tooltips = {
        tileset = "The tileset to delete"
    },
    fieldInformation = {
        tileset = {
            fieldType = "string",
            options = {}
        }
    },
    
}
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        local topts = {}
        for k,v in pairs(tilesetHandler.fgTilesets) do
            if not (tilesetHandler.isVanilla(v.path,projectDetails) or (v.used and v.used>0)) then
                table.insert(topts,{k,k}) 
            end
        end
        table.sort(topts,function (a,b)
            return a[1]<b[1]
        end)
        script.fieldInformation.tileset.options = topts
    else
        error("Project details invalid. Load a project to fix this")
    end
end
function script.run(args)
    local projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    local target = tilesetHandler.prepareXmlLocation(true,projectDetails)
    script.nextScript=warningGenerator.makeWarning( 
        {string.format("You are deleting the tileset %s. This change applies accross your.",args.tileset),
            "whole campaign. Deleting a tileset can be undone as normal. The tileset file will be",
            string.format("stored in %s and eventually deleted if",safeDelete.folder),
            "this is not reversed. This can result in the permanent loss of the tileset image.",
            "Are you sure you want to do this?"}
        ,args.tileset,nil,nil,nil,nil)
    local tilesetDetails = tilesetHandler.fgTilesets[args.tileset]
    local tpath=fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Gameplay","tilesets",tilesetDetails.path..".png")
    local remTileset = function()
        local success,message,humMessage=tilesetHandler.removeTileset(args.tileset,true,target)
        if not success then
            logging.warning(string.format("Failed to write to %s due to the following error:\n%s",target,message),1)
        end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success, humMessage
    end
    local unRemTileset = function ()
        local success,message,humMessage =tilesetHandler.addTileset(tilesetDetails.path,args.tileset,tilesetDetails.copy or "",tilesetDetails.sound or 0,tilesetDetails.ignores or {},tilesetHandler.templateInfo or "", tilesetDetails.masks or "",true,target)
        if not success then
            logging.warning(string.format("Failed to write to %s due to the following error:\n%s",target,message),1)
        end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success, humMessage
    end
    local success, message, humMessage
    local deleteFile = function ()
        
        success,message = safeDelete.revdelete(tpath)
        if not success then
            logging.warning(string.format("Failed to remove tileset file due to a following error:\n%s",message),1)
            return success,"failed to remove tileset due to filesystem error"
        end
        return true, humMessage
    end
    local recoverFile = function ()
        success,message = os.rename(success,tpath)
        if not success then
            error(string.format("Could not recover tileset %s due to the following error:\n%s",args.tileset,message))
        end
        
        
    end
    local remSnap = fallibleSnapshot.create("remove tileset",{},unRemTileset,remTileset)
    local fileSnap = fallibleSnapshot.create("delete file",{},recoverFile,deleteFile)
    script.nextScript.run = function (args)
        local success,message = remTileset()
        if not success then
            notifications.notify(message)
            return
        end
        success,message = deleteFile()
        if not success then
            notifications.notify(message)
            local suc,mess = recoverFile()
            if not suc then
                notifications.notify(mess)
            end
            return
        end
        history.addSnapshot(fallibleSnapshot.multiSnapshot("Delete tileset",{remSnap,fileSnap}))
    end
end
return script