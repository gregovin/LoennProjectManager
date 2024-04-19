local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local state = require("loaded_state")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local history = require("history")
local logging = require("logging")
local projectLoader =  mods.requireFromPlugin("libraries.projectLoader")
local utils = require("utils")
local tilesetHandler = mods.requireFromPlugin("libraries.tilesetHandler")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local celesteRenderer = require("celeste_render")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")
local celesteEnums = require("consts.celeste_enums")

local script = {
    name = "LinkRemoteBgTileset",
    displayName = "Link Remote Bg Tileset",
    tooltip = "Add a background template or tileset from another mod. Useful with asset packs",
    layer="background",
    verb = "import",
    parameters = {
        path = "",
        name= "",
        sound = 0,
        ignores = {},
        template = "",
        customMask = "",
        }
    ,
    tooltips = {
        path="The path to the remote tileset in the other mod. If that mod has an example xml, coppy this from the \"path\" attribute",
        name="The display name for your tileset",
        sound = "The sound to play when this tile is stepped on",
        ignores = "which tilesets this tile should ignore",
        template="The template you are using. Edit to create a custom template",
        customMask="The mask to apply for this tileset or template. Overides the selected template\nIf you are instatiating a template, or the mod has an example xml, copy the bit that goes between the <tileset> tags here", 
    },
    fieldInformation = {
        path={
            fieldType = "string",
            validator = function(v)
                return string.find(v,"/")
            end
        },
        name = {
            fieldType="loennProjectManager.xmlAttribute"
        },
        sound = {
            fieldType="integer",
            options = celesteEnums.tileset_sound_ids
        },
        ignores={
            fieldType="loennProjectManager.multiselect",
            multiselectName = "ignores",
            options = {
                {"all","*"}
            }
        },
        template={
            fieldType="loennProjectManager.xmlAttribute",
            options = {{"",""}},
            editable = true,
        },
        customMask={fieldType="string"}
    },
    fieldOrder={
        "path","name","sound","template","ignores","customMask"
    }
}


function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        script.fieldInformation.template.options=tilesetHandler.sortedTilesetOpts(tilesetHandler.getTemplates(false))
        local ignoreOptions = tilesetHandler.sortedTilesetOpts(tilesetHandler.getTilesets(false))
        table.insert(ignoreOptions,{"All","*"})
        script.fieldInformation.ignores.options=ignoreOptions
    elseif not projectDetails.name then
        error("Cannot find tilesets because no project is selected!",2)
    elseif not projectDetails.username then
        error("Cannot find tilesets because no username is selected. This should not happen",2)
    elseif not projectDetails.campaign then
        error("Cannot find tilesets because no campaign is selected!",2)
    else
        error("Cannot find tilesets because no map is selected!",2)
    end
end
function script.run(args)
    local projectDetails = pUtils.getProjectDetails()
    --error if the state doesn't match
    projectLoader.assertStateValid(projectDetails)
    --determine where the backgroundTiles.xml should be
    local target = tilesetHandler.prepareXmlLocation(false,projectDetails)
    
    local hadBgTiles = state.side.meta and state.side.meta.BackgroundTiles
    local copyMask = ""
    local templateInfo = ""
    if tilesetHandler.isTileset(args.template,false) then
        copyMask = args.template
    else
        templateInfo = args.template
    end
    local tilesetName =args.name
    if not tilesetName then
        tilesetName = utils.filename(args.path,"/") or args.path
        tilesetName = utils.humanizeVariableName(tilesetName)
    end
    local addTileset = function()
        local success, logMessage,displayMessage = tilesetHandler.addTileset(args.path,args.name,copyMask,args.sound,args.ignores,templateInfo,args.customMask,false,target)
        if not success then logging.warning("failed to write to %s due to the following error:\n%s",target,logMessage) end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success,string.format("Failed to add tileset: %s",displayMessage)
    end
    local remTileset = function()
        local success, logMessage, humMessage = tilesetHandler.removeTileset(tilesetName,false,target)
        if not success then logging.warning("failed to write to %s due to the following error:\n%s",target,logMessage) end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success,string.format("Failed to remove tileset: {}",humMessage)
    end
    local snap = fallibleSnapshot.create("Add Tileset",{success=true},remTileset,addTileset)
    local success,message = addTileset()
    if not success then 
        notifications.notify(message)
        return
    end
    if (not hadBgTiles) and success then
        local diffp=pUtils.pathDiff(fileSystem.joinpath(modsDir,projectDetails.name),target)
        tilesetHandler.updateCampaignMetadata(projectDetails,state,false,diffp)
        state.side.meta = state.side.meta or {}
        state.side.meta.BackgroundTiles=diffp
        settings.set("BackgroundTilesXml",diffp,"recentProjectInfo")
        if not state.side.meta.ForegroundTiles then
            notifications.notify("Save and restart loenn to load your tileset")
        end
    end
    celesteRenderer.loadCustomTilesetAutotiler(state)
    history.addSnapshot(snap)
end
return script