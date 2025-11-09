local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local notifications = require("ui.notification")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local logging = require("logging")
local state = require("loaded_state")
local settings = mods.requireFromPlugin("libraries.settings")

local script = {
    name = "packProject",
    displayName = "Pack Project",
    tooltip = "Pack a loose project into the apropriate structure",
    verb = "Pack",
    parameters = {
        modIdentifier = "",
        username = settings.get("username", ""),
        campaignName = "",
        mapIdentifier = "",
    },
    tooltips = {
        modIdentifier =
        "The identifier for mod. This will be the top level folder your mod will be saved in. It should be unique.\n Must be a valid portable filename. \nFor many mods it makes sense for this to be the same as or similar your Map Name.",
        username = "Your username. Must be a valid portable filename",
        campaignName =
        "The name for your campaign. It should be unique among your projects. If unsure, you can use your map or mod name\nMust be a valid portable filename.",
        mapIdentifier =
        "The identifier for your map. If you are making a multipart campaigns, should start with a 1 or 0 indexed number.\nMust be a valid portable filename",
    },
    fieldInformation = {
        modIdentifier = { fieldType = "loennProjectManager.fileName" },
        username = { fieldType = "loennProjectManager.fileName" },
        campaignName = { fieldType = "loennProjectManager.fileName" },
        mapIdentifier = { fieldType = "loennProjectManager.fileName" },
    },
    fieldOrder = {
        "modIdentifier", "username", "campaignName", "mapIdentifier"
    }
}
function script.prerun()
    local filename = state.filename
    -- this code can **only** excecute from the relevant event so we assume this is sane
    local rpth = pUtils.pathDiff(modsDir, filename)
    logging.info(rpth)
    -- assume srelpath has exactly one element
    script.parameters.mapIdentifier = fileSystem.stripExtension(rpth)
    script.parameters.modIdentifier = script.parameters.mapIdentifier
end

function script.run(args)
    local target = fileSystem.joinpath(modsDir, args.modIdentifier, "Maps", args.username, args.campaignName)
    local success, message = fileSystem.mkpath(target)
    if success then
        target = fileSystem.joinpath(target, args.mapIdentifier .. ".bin")
        local success, message = os.rename(state.filename, target) --make sure to update this if utf8 aware filesystem is next update
        if not success then
            notifications.notify("Could not pack bin due to filesystem error", state.filename, target,
                message)
            logging.wag(string.format("Failed to move file %s to %s due to the following error:\n%s", state.filename,
                target))
            return
        end
        settings.set("name", args.modIdentifier, "recentProjectInfo")
        settings.set("SelectedCampaign", args.campaignName, "recentProjectInfo")
        settings.set("campaigns", { args.campaignName }, "recentProjectInfo")
        settings.set("maps", { args.mapIdentifier }, "recentProjectInfo")
        settings.set("recentmap", args.mapIdentifier, "recentProjectInfo")
        projectLoader.clearMetadataCache()
        notifications.notify(string.format("Switched to Project %s", args.modIdentifier), 1)
        state.loadFile(target)
    else
        notifications.notify("Could not create project due to filesystem error", 10)
        logging.warning(string.format("Failed to create project %s due to the following error:\n%s", args.modIdentifier,
            message))
    end
end

return script
