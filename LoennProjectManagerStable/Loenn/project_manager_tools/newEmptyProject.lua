local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local logging = require("logging")
local projectLoader=mods.requireFromPlugin("libraries.projectLoaders")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local script = {
    name = "newEmptyProject",
    displayName = "New Empty Project",
    tooltip = "Create a new Celeste modded project. Makes a toplevel folder and sets the current project directory. You can then add campaigns using the provided scripts.\n If you wish to make a small campaign or single map, use the New Standard Project Script",
    tooltips = {
        modIdentifier = "The identifier for mod. This will be the top level folder your mod will be saved in",
        username = "Your username",
    },
    parameters = {
        modIdentifier = "",
        username = settings.get("username",""),
    },
    fieldInformation = {
        modIdentifier = {fieldType = "string"},
        username = {fieldType = "string"},
    },
    fieldOrder={
        "modIdentifier","username"
    }
}

function script.run(args)
    logging.info("Creating empty project "..args.modIdentifier)
    local target= fileSystem.joinpath(modsDir,args.modIdentifier,"Maps",args.username)
    local success,message = fileSystem.mkpath(target)
    if success then
        projectLoader.clearMetadataCache()
        settings.set("username",args.username)
        settings.set("name",args.modIdentifier,"recentProjectInfo")
        notifications.notify(string.format("Switched to Project %s", args.modIdentifier), 10)
    else
        notifications.notify("Could not create project due to filesystem error", 10)
        logging.warning(string.format("Failed to create project %s due to the following error:\n%s",args.modIdentifier,message))
    end
end

return script