local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")

local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local logging = require("logging")
local projectLoader=mods.requireFromPlugin("libraries.projectLoaders")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local script = {
    name = "manageMaps",
    displayName = "Choose Map",
    tooltip = "Select or Create a map for your campaignt",
    tooltips = {
        mapName = "The name for your map. Select from the list or enter a new entry to create a new map",
    },
    parameters = {
        mapName = "",
    },
    fieldInformation = {
        mapName = {
            fieldType = "string",
            options = {},
            editable = true
        },
    },
}

function script.prerun() 
    script.fieldInformation.mapName.options=settings.get("maps",{},"recentProjectInfo")
end
local function getMapLocation(projectDetails,mapName)
    return fileSystem.joinpath(modsDir,projectDetails.projectName,"Maps",projectDetails.username,
            projectDetails.campaign,mapName..".bin")
end
function script.run(args)
    local projectDetails = {
        projectName = settings.get("name",nil,"recentProjectInfo"),
        username = settings.get("username",nil),
        campaign = settings.get("SelectedCampaign",{},"recentProjectInfo"),
        maps = settings.get("maps",{},"recentProjectInfo")
    }
    if projectDetails.projectName and projectDetails.username and projectDetails.campaign then
        local target= getMapLocation(projectDetails,args.mapName)
        logging.info("creating map at "..target)
        if $(projectDetails.maps):contains(args.mapName) then
            projectLoader.loadMap(target,args.mapName)
        else
            projectLoader.newMap(target,args.mapName,projectDetails)
        end
        projectLoader.clearMetadataCache()
    elseif not projectDetails.projectName then
        notifications.notify("No project selected! Select or Create a project amd try again.", 10)
        logging.warning(string.format("Failed to create map %s because no project has been set",args.mapName))
    elseif not projectDetails.username then
        notifications.notify("No username detected! This state should not be reachable in a standard project.", 10)
        logging.warning(string.format("Failed to create map %s because no username has been detected",args.mapName))
    else
        notifications.notify("No campaign detected! Select or create one and try again", 10)
        logging.warning(string.format("Failed to create map %s because no campaign has been detected",args.mapName))
    end
end
return script