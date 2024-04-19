local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local logging = require("logging")
local mapcoder = require("mapcoder")
local state = require("loaded_state")
local mapStruct = require("structs.map")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local script = {
    name = "newStandardProject",
    displayName = "New Standard Project",
    tooltip = "Create a standard celeste project with a campaign and 1 map",
    layer="project",
    tooltips = {
        modIdentifier = "The identifier for mod. This will be the top level folder your mod will be saved in. It should be unique.\n Must be a valid portable filename. \nFor many mods it makes sense for this to be the same as or similar your Map Name.",
        username = "Your username. Must be a valid portable filename",
        campaignName= "The name for your campaign. It should be unique among your projects. If unsure, you can use your map or mod name\nMust be a valid portable filename.",
        mapIdentifier="The identifier for your map. If you are making a multipart campaigns, should start with a 1 or 0 indexed number.\nMust be a valid portable filename",
    },
    parameters = {
        modIdentifier = "",
        username = settings.get("username",""),
        campaignName= "",
        mapIdentifier="",
    },
    fieldInformation = {
        modIdentifier = {fieldType = "loennProjectManager.fileName"},
        username = {fieldType = "loennProjectManager.fileName"},
        campaignName= {fieldType = "loennProjectManager.fileName"},
        mapIdentifier={fieldType = "loennProjectManager.fileName"},
    },
    fieldOrder = {
        "modIdentifier","username","campaignName","mapIdentifier"
    }
}
local emptyMap = {
    _type ="map",
    package = "", -- probably fine to have this empty
    rooms = {},
    filers = {},
    stylesFg = {},
    stylesBg = {},
}
function script.run(args)
    logging.info("Creating standard project "..args.modIdentifier)
    settings.set("username",args.username)
    local target= fileSystem.joinpath(modsDir,args.modIdentifier,"Maps",args.username,args.campaignName)
    local success,message = fileSystem.mkpath(target)
    if success then
        settings.set("name",args.modIdentifier,"recentProjectInfo")
        settings.set("SelectedCampaign",args.campaignName,"recentProjectInfo")
        settings.set("campaigns",{args.campaignName},"recentProjectInfo")
        settings.set("maps",{args.mapIdentifier},"recentProjectInfo")
        settings.set("recentmap",args.mapIdentifier,"recentProjectInfo")
        projectLoader.clearMetadataCache()
        notifications.notify(string.format("Switched to Project %s", args.modIdentifier), 1)
        target = fileSystem.joinpath(target,args.mapIdentifier .. ".bin")
        mapcoder.encodeFile(target,mapStruct.encode(emptyMap)) -- May fail silently?
        state.loadFile(target)
    else
        notifications.notify("Could not create project due to filesystem error", 10)
        logging.warning(string.format("Failed to create project %s due to the following error:\n%s",args.modIdentifier,message))
    end
end

return script