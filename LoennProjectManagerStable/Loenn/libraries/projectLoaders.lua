local state = require("loaded_state")
local mapStruct = require("structs.map")
local sideStruct = require("structs.side")
local mapcoder= require("mapcoder")
local mods = require("mods")
local fileSystem = require("utils.filesystem")
local notifications = require("ui.notification")
local settings = mods.requireFromPlugin("libraries.settings")
local logging = require("logging")
local p_utils= mods.requireFromPlugin("libraries.projectUtils")
local utils = require("utils")
local fileLocations = require("file_locations")
local xmlHandler = require("lib.xml2lua.xmlhandler.tree")
local xml2lua = require("lib.xml2lua.xml2lua")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local loaders = {}
function loaders.loadMap(mapLocation,mapName)
    state.loadFile(mapLocation)
    settings.set("recentmap",mapName,"recentProjectInfo")
end
local emptyMap = {
    _type ="map",
    package = "", -- probably fine to have this empty
    rooms = {},
    filers = {},
    stylesFg = {},
    stylesBg = {},
}
function loaders.newMap(mapLocation,mapName,projectDetails)
    table.insert(projectDetails.maps,mapName)
    mapcoder.encodeFile(mapLocation,mapStruct.encode(emptyMap)) -- May fail silently?
    state.loadFile(mapLocation)
    settings.set("recentmap",mapName,"recentProjectInfo")
    settings.set("maps",projectDetails.maps,"recentProjectInfo")
end
function loaders.loadCampaign(campaignLocation,campaignName)
    local maps = ($(p_utils.list_dir(campaignLocation)):map(file->fileSystem.stripExtension(file)))()
    settings.set("SelectedCampaign",campaignName,"recentProjectInfo")
    settings.set("maps",maps,"recentProjectInfo")
    if #maps ==1 then
        local mapName=maps[1]
        loaders.loadMap(fileSystem.joinpath(campaignLocation,mapName..".bin"),mapName)
    elseif #maps>1 then
        notifications.notify("Campaign loaded. Select a map to continue", 10)
    else
        notifications.notify("Campaign loaded. Create a map to continue", 10)
    end
end
function loaders.newCampaign(campaignLocation,campaignName,projectDetails)
    local success,message = fileSystem.mkpath(campaignLocation)
    if success then
        settings.set("SelectedCampaign",campaignName,"recentProjectInfo")
        table.insert(projectDetails.campaigns,campaignName)
        settings.set("campaigns",projectDetails.campaigns,"recentProjectInfo")
        settings.set("maps",{},"recentProjectInfo")
        settings.set("recentmap",nil,"recentProjectInfo")
        notifications.notify(string.format("Switched to Campaign %s, create a map to continue",campaignName), 10)
    else
        notifications.notify("Could not create campaign due to filesystem error", 10)
        logging.warning(string.format("Failed to create campaign %s due to the following error:\n%s",campaignName,message))
    end
end
local tilesets = {}
local revDict = {}
local templates = {}
function loaders.clearMetadataCache()
    tilesets = {}
    templates = {}
    revDict = {}
    settings.set("tilesetTemplates",nil,"recentProjectInfo")
    settings.set("tilesets",nil,"recentProjectInfo")
    settings.set("animatedTilesets",nil,"recentProjectInfo")
    settings.set("tileIdNameMap",revDict,"recentProjectInfo")
    settings.set("metaDataCacheValid",false)
end
local function processTilesetXml(xmlString,foreground)
    local parser = xml2lua.parser(xmlHandler)
    local xml = utils.stripByteOrderMark(xmlString)
    parser:parse(xml)
    local tilesetRoot = xmlHandler.root.Data.Tileset
    for i, element in ipairs(tilesetRoot) do
        local id = element._attr.id
        local copy = element._attr.copy
        local ignores = element._attr.ignores or ""
        local path= element._attr.path
        local sound = element._attr.sound
        local templateInfo = element._attr.templateInfo
        local name = utils.humanizeVariableName(path)
        tilesets[name]={
            id = id,
            copy = copy,
            path = path,
            foreground = foreground,
            sound = sound,
            ignores = table.flip(string.split(ignores,",")),
            templateInfo =templateInfo,
            masks = element.set
        }
        revDict[id]=name
        if templateInfo then
            local inner = {
                name= name,
                id = id,
                mask=element.set
            }
            if not templates[templateInfo] then
                templates[templateInfo] = {} 
            end
            if not templates[templateInfo].tileset then
                templates[templateInfo].tileset = {} 
            end 
            if foreground then
                templates[templateInfo].tileset.foreground = inner
            else
                templates[templateInfo].tileset.background = inner
            end
        end
        local check = nil
        if foreground then
           check = (t-> t.tileset.foreground and t.tileset.foreground.id == copy)     
        else
            check = (t-> t.tileset.background and t.tileset.background.id == copy)
        end
        if copy and not $(templates):values():find(check) then
            local target = $(tilesets):values():find(t->t.foreground == foreground and t.id==copy)
            if not target then
                error(string.format("Copied tilesets must be defined before the tileset coping from them: %s copies %s", id, copy))
            end
            local targetName= utils.humanizeVariableName(target.path)
            local t_name= string.format("%s(%s)",target.id,targetName)
            local inner = {
                name=targetName,
                id=target.id,
                masks=target.masks
            }
            templates[t_name]={}
            templates[t_name].tileset = {}
            if foreground then
                templates[t_name].tileset.foreground=inner
            else
                templates[t_name].tileset.background=inner
            end
        end
    end
end
function loaders.loadMetadataDetails(projectDetails)
    logging.info("loading metadata")
    -- read the map metadata
    local mapLocation =fileSystem.joinpath(modsDir,projectDetails.name,"Maps",projectDetails.username,projectDetails.campaign,projectDetails.map..".bin")
    local rawData=mapcoder.decodeFile(mapLocation)
    local mapData = sideStruct.decode(rawData)
    local foregroundTilesXml = mapData.meta.ForegroundTiles --nil if not used, relative to mod root when used
    local backgroundTilesXml = mapData.meta.BackgroundTiles
    local animatedTilesXml = mapData.meta.AnimatedTiles
    --process xmls
    logging.info("processing xmls")
    local foregroundTilestring = p_utils.getXmlString(foregroundTilesXml,projectDetails,"xmls/ForegroundTiles.xml")
    processTilesetXml(foregroundTilestring,true)
    processTilesetXml(p_utils.getXmlString(backgroundTilesXml,projectDetails,"xmls/BackgroundTiles.xml"),false)
    logging.info("finished processing")
    --set settings correctly
    settings.set("foregroundTilesXml",foregroundTilesXml,"recentProjectInfo")
    settings.set("backgroundTilesXml",backgroundTilesXml,"recentProjectInfo")
    settings.set("animatedTilesXml",animatedTilesXml,"recentProjectInfo")
    settings.set("tilesetTemplates",templates,"recentProjectInfo")
    settings.set("tilesets",tilesets,"recentProjectInfo")
    settings.set("tileIdNameMap",revDict,"recentProjectInfo")
    settings.set("metaDataCacheValid",true)
end
return loaders