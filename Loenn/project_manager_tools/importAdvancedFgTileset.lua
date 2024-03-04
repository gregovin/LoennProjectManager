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
    name = "importFgTileset",
    displayName = "Import Fg Tileset",
    tooltip = "Import a tileset file into your campaign as a foreground tileset",
    verb = "import",
    parameters = {
        tilesetFile = "",
        name= "",
        copyFile = false,
        sound = 0,
        ignores = {},
        template = "z",
        customMask = "",
        }
    ,
    tooltips = {
        tilesetFile="The png file for your tileset",
        name="The name you want your tileset to be displayed under in loenn",
        copyFile="By default, the file will be moved from its current location. If checked, it will be coppied instead",
        sound = "The sound to play when this tile is stepped on",
        ignores = "Which tilesets this tile should ignore. Tilesets selected will be treated as air when drawing this tileset",
        template="The template you are using.\nTo add a new template, enter the name here and use the custom mask field to specify the masking",
        customMask="The mask to apply for this tileset or template. Overides the selected template\nIf you are instatiating a template, copy the bit that goes between the <tileset> tags here", 
    },
    fieldInformation = {
        tilesetFile={
            fieldType = "loennProjectManager.filePath",
            extension="png"
        },
        copyFile ={fieldType="boolean"},
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
        "tilesetFile","copyFile","name","sound","template","ignores","customMask"
    }
}


function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        script.fieldInformation.template.options=tilesetHandler.sortedTilesetOpts(tilesetHandler.getTemplates(true))
        local ignoreOptions = tilesetHandler.sortedTilesetOpts(tilesetHandler.getTilesets(true))
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
    --determine where the foregroundTiles.xml should be
    local target = tilesetHandler.prepareXmlLocation(true,projectDetails)
    --check if the file is a real png
    local png, logMsg,notifMsg = pUtils.isPng(args.tilesetFile)
    if not png then
        notifications.notify(notifMsg)
        logging.warning(logMsg)
    end
    --determine the path the tileset should go to and make it
    local tilesetName = fileSystem.filename(args.tilesetFile)
    local tilesetDir,path= tilesetHandler.prepareTilesetPath(projectDetails)
    tilesetDir = fileSystem.joinpath(tilesetDir,path)
    
    local hadFgTiles = state.side.meta and state.side.meta.ForegroundTiles
    local copyMask = ""
    local templateInfo = ""
    if tilesetHandler.isTileset(args.template,true) then
        copyMask = args.template
    else
        templateInfo = args.template
    end
    local pName = fileSystem.stripExtension(tilesetName)
    
    --remember the current name that would be given to the tilesest
    local preferedDefaultName = utils.humanizeVariableName(pName)
    if tilesetHandler.fgTilesets[(#args.name>0 and args.name) or preferedDefaultName] then
        notifications.notify("Cannot create a tileset with name "..pName..", A tileset with that name allready exists")
        return
    end
    pName = string.lower(pName) -- to avoid problems with windows being case-insensitve we will just use one case!
    while fileSystem.isFile(fileSystem.joinpath(tilesetDir,pName..".png")) do
        pName = pName..string.char(math.random(97, 97 + 25)) --add a random lowercase letter to the filename until its unique
    end
    tilesetName = pName..".png"--update the tileName to the new desired path
    --if we changed the display name then we should update it if we didn't allready have a displayName
    if utils.humanizeVariableName(pName)~=preferedDefaultName then
        args.name=(#args.name>0 and args.name) or preferedDefaultName
    end
    path =fileSystem.convertToUnixPath(fileSystem.joinpath(path,pName))
    local fileOp = function ()
        local success,message = tilesetHandler.mvOrCPtileset(args.copyFile,args.tilesetFile,fileSystem.joinpath(tilesetDir,tilesetName))
        if not success then logging.warning(message) end
        local adj = args.copyFile and "copy" or "move"
        return success, string.format("Failed to %s tileset file due to a filesystem error",adj)
    end
    local addTileset = function()
        local success, logMessage,displayMessage = tilesetHandler.addTileset(path,args.name,copyMask,args.sound,args.ignores,templateInfo,args.customMask,true,target)
        if not success then logging.warning("failed to write to %s due to the following error:\n%s",target,logMessage) end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success,string.format("Failed to add tileset: %s",displayMessage)
    end
    local remTileset = function()
        local success, logMessage, humMessage = tilesetHandler.removeTileset(args.name,true,target)
        if not success then logging.warning("failed to write to %s due to the following error:\n%s",target,logMessage) end
        celesteRenderer.loadCustomTilesetAutotiler(state)
        return success,string.format("Failed to remove tileset: {}",humMessage)
    end
    local revFileOp = function ()
        local success,message
        if args.copyFile then
            success,message=fileSystem.remove(fileSystem.joinpath(tilesetDir,tilesetName))
        else
            success,message=fileSystem.rename(fileSystem.joinpath(tilesetDir,tilesetName),args.tilesetFile)
        end
        if not success then
            local verb
            if args.copyFile then
                verb="copy"
            else
                verb="move"
            end
            logging.warning(string.format("failed to undo %s due to the following error: %s",verb,message))
            return false,"failed to remove tileset file due to filesystem error"
        end
        return true
    end
    local snap1 = fallibleSnapshot.create("Move or Copy",{success=true},revFileOp,fileOp)
    local snap2 = fallibleSnapshot.create("Add Tileset",{success=true},remTileset,addTileset)
    local success,message = fileOp()
    if not success then 
        notifications.notify(message)
        return
    end
    success,message = addTileset()
    if not success then
        notifications.notify(message)
        local succ, mess = revFileOp()
        if not succ then
            notifications.notify(mess)
        end
        return
    end
    if (not hadFgTiles) and success then
        local diffp=pUtils.pathDiff(fileSystem.joinpath(modsDir,projectDetails.name),target)
        tilesetHandler.updateCampaignMetadata(projectDetails,state,true,diffp)
        state.side.meta = state.side.meta or {}
        state.side.meta.ForegroundTiles=diffp
        settings.set("foregroundTilesXml",diffp,"recentProjectInfo")
        if not state.side.meta.BackgroundTiles then
            notifications.notify("Save and restart loenn to load your tileset")
        end
        celesteRenderer.loadCustomTilesetAutotiler(state)
    end
    
    snap2.data.success=success
    history.addSnapshot(fallibleSnapshot.multiSnapshot("Add Fg tileset",{snap1,snap2}))
end
return script