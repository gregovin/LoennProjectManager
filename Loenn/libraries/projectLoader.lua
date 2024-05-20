local state = require("loaded_state")
local sideStruct = require("structs.side")
local mapcoder = require("mapcoder")
local mods = require("mods")
local fileSystem = require("utils.filesystem")
local notifications = require("ui.notification")
local settings = mods.requireFromPlugin("libraries.settings")
local logging = require("logging")
local p_utils = mods.requireFromPlugin("libraries.projectUtils")
local tilesetHandler = mods.requireFromPlugin("libraries.tilesetHandler")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fileLocations = require("file_locations")

local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

--- A module for loading various parts of a project
local loaders = {}
---A helper function to load a map into project manager
---@param mapLocation string the path to the map to load
function loaders.loadMap(mapLocation)
    local campaign = settings.get("SelectedCampaign", nil, "recentProjectInfo")
    local pfground = fileSystem.joinpath("Graphics", campaign, "ForegroundTiles.xml")
    local pbground = fileSystem.joinpath("Graphics", campaign, "BackgroundTiles.xml")
    local tplevel = fileSystem.joinpath(modsDir, settings.get("name", nil, "recentProjectInfo"))
    local mapName = fileSystem.stripExtension(fileSystem.filename(mapLocation))
    if fileSystem.isFile(fileSystem.joinpath(tplevel, pfground)) or fileSystem.isFile(fileSystem.joinpath(tplevel, pbground)) then
        local s = sideStruct.decode(mapcoder.decodeFile(mapLocation))
        s.meta = s.meta or {}
        if fileSystem.isFile(fileSystem.joinpath(tplevel, pfground)) then
            s.meta.ForegroundTiles = s.meta.ForegroundTiles or pfground
        end
        if fileSystem.isFile(fileSystem.joinpath(tplevel, pbground)) then
            s.meta.BackgroundTiles = s.meta.BackgroundTiles or pbground
        end
        mapcoder.encodeFile(mapLocation, sideStruct.encode(s))
    end
    state.loadFile(mapLocation)
    settings.set("recentmap", mapName, "recentProjectInfo")
end

--A simple table for empty maps so we can quickly encode one
local emptySide = {
    map = {
        _type = "map",
        package = "", -- probably fine to have this empty
        rooms = {},
        filers = {},
        stylesFg = {},
        stylesBg = {},
    },
    meta = {}
}
---Create a new map
---@param mapLocation string the path the map should be created at
---@param projectDetails table the project details for the currently loaded project
function loaders.newMap(mapLocation, projectDetails)
    local mapName = fileSystem.stripExtension(fileSystem.filename(mapLocation))
    table.insert(projectDetails.maps, mapName)
    local topdir = fileSystem.joinpath(modsDir, projectDetails.name)
    local xmlpath = fileSystem.joinpath("Graphics", projectDetails.campaign)
    --check for campaign level xmls and add them to the map
    if fileSystem.isFile(fileSystem.joinpath(topdir, xmlpath, "ForegroundTiles.xml")) then
        emptySide.meta.ForegroundTiles = fileSystem.joinpath(xmlpath, "ForegroundTiles.xml")
    else
        emptySide.meta.ForegroundTiles = nil
    end
    if fileSystem.isFile(fileSystem.joinpath(topdir, xmlpath, "BackgroundTiles.xml")) then
        emptySide.meta.BackgroundTiles = fileSystem.joinpath(xmlpath, "BackgroundTiles.xml")
    else
        emptySide.meta.BackgroundTiles = nil
    end
    --write the new map to disk
    mapcoder.encodeFile(mapLocation, sideStruct.encode(emptySide)) -- May fail silently?
    --load the new map
    state.loadFile(mapLocation)
    --make sure we update the state
    settings.set("recentmap", mapName, "recentProjectInfo")
    settings.set("maps", projectDetails.maps, "recentProjectInfo")
end

---A helper function to load a campaign into loenn pm
---@param campaignLocation string the path to the campaign
function loaders.loadCampaign(campaignLocation)
    --get the map names from the filenames within the campaign location
    local maps = ($(p_utils.list_dir(campaignLocation)):filter(file->(fileSystem.fileExtension(file)=="bin")):map(file->(fileSystem.stripExtension(file))))()
    local campaignName = fileSystem.filename(campaignLocation)
    --update the state
    settings.set("SelectedCampaign", campaignName, "recentProjectInfo")
    settings.set("maps", maps, "recentProjectInfo")
    --if there is exactly one map, load it, otherwise request user intervention
    if #maps == 1 then
        local mapName = maps[1]
        loaders.loadMap(fileSystem.joinpath(campaignLocation, mapName .. ".bin"))
    elseif #maps > 1 then
        notifications.notify("Campaign loaded. Select a map to continue", 10)
    else
        notifications.notify("Campaign loaded. Create a map to continue", 10)
    end
end

---Creates a new campaign
---@param campaignLocation string the path to the campaign
---@param projectDetails table the project details for the currently loaded project
function loaders.newCampaign(campaignLocation, projectDetails)
    local success, message = fileSystem.mkpath(campaignLocation) --make the path
    local campaignName = fileSystem.filename(campaignLocation)
    if success then
        --if it worked then add the campaign details to the relevant places
        settings.set("SelectedCampaign", campaignName, "recentProjectInfo")
        table.insert(projectDetails.campaigns, campaignName)
        settings.set("campaigns", projectDetails.campaigns, "recentProjectInfo")
        settings.set("maps", {}, "recentProjectInfo")
        settings.set("recentmap", nil, "recentProjectInfo")
        notifications.notify(string.format("Switched to Campaign %s, create a map to continue", campaignName), 10)
    else
        --otherwise log and notify
        notifications.notify("Could not create campaign due to filesystem error", 10)
        logging.warning(string.format("Failed to create campaign %s due to the following error:\n%s", campaignName,
            message))
    end
end

---Clears loenn PM's metadata cache. Should be called whenever a new map is loaded
function loaders.clearMetadataCache()
    tilesetHandler.clearTilesetCache()
    metadataHandler.clearMetadata()
    loaders.cacheValid = false
end

---Errors if the state is invalid, otherwise does nothing
---@param projectDetails ProjectDetails the project details for the currently loaded project
function loaders.assertStateValid(projectDetails)
    local mapLocation = fileSystem.joinpath(modsDir, projectDetails.name, "Maps", projectDetails.username,
        projectDetails.campaign, projectDetails.map .. ".bin")
    if state.filename ~= mapLocation then
        error("Project details out of sync! Open a project or use the resync open project tool to fix this", 2)
    end
end

---Load metadata for the current project. This should be called if metadata is needed but loaders.cacheValid is false
---@param projectDetails ProjectDetails
function loaders.loadMetadataDetails(projectDetails)
    logging.info("loading metadata")
    -- read the map metadata
    loaders.assertStateValid(projectDetails)
    local mapData = state.side
    local foregroundTilesXml = (mapData.meta and mapData.meta.ForegroundTiles)
    local backgroundTilesXml = (mapData.meta and mapData.meta.BackgroundTiles)
    local animatedTilesXml = (mapData.meta and mapData.meta.AnimatedTiles)
    --process xmls
    local foregroundTilestring = p_utils.getXmlString(foregroundTilesXml, projectDetails, "xmls/ForegroundTiles.xml")
    local backgroundTilestring = p_utils.getXmlString(backgroundTilesXml, projectDetails, "xmls/BackgroundTiles.xml")
    tilesetHandler.processTilesetXml(foregroundTilestring, true, projectDetails)
    tilesetHandler.processTilesetXml(backgroundTilestring, false, projectDetails)
    --set settings correctly
    settings.set("foregroundTilesXml", foregroundTilesXml, "recentProjectInfo")
    settings.set("backgroundTilesXml", backgroundTilesXml, "recentProjectInfo")
    settings.set("animatedTilesXml", animatedTilesXml, "recentProjectInfo")
    --read meta.yaml
    metadataHandler.readMetadata(projectDetails)
    loaders.cacheValid = true
end

return loaders
