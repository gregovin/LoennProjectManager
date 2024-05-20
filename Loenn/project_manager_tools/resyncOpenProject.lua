local state = require("loaded_state")
local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local notifications = require("ui.notification")
local settings = mods.requireFromPlugin("libraries.settings")
local logging = require("logging")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")

local script = {
    name = "resyncProject",
    displayName = "Resync Open Project",
    layer = "project",
    tooltip = "Attempts to load the project for the currently selected map",
}

function script.run(args)
    local mapLocal = state.filename
    if not mapLocal then
        notifications.notify("No map loaded")
        return
    end
    if not string.find(mapLocal, modsDir, 1, true) then
        notifications.notify("Cannot load maps outside of the mods directory.")
        return
    end
    local srelpath = fileSystem.splitpath(pUtils.pathDiff(modsDir, mapLocal))
    if #srelpath ~= 5 or srelpath[2] ~= "Maps" then
        notifications.notify("cannot load project, structure invalid")
    end
    projectLoader.clearMetadataCache()
    logging.info("Resyncing")
    settings.set("name", srelpath[1], "recentProjectInfo")
    settings.set("username", srelpath[3])
    local target = fileSystem.joinpath(modsDir, srelpath[1], "Maps", srelpath[3])
    settings.set("campaigns", pUtils.list_dir(target), "recentProjectInfo")
    settings.set("SelectedCampaign", srelpath[4], "recentProjectInfo")
    target = fileSystem.joinpath(target, srelpath[4])
    local maps = ($(pUtils.list_dir(target)):map(file->(fileSystem.stripExtension(file))))()
    settings.set("maps", maps, "recentProjectInfo")
    settings.set("recentmap", fileSystem.stripExtension(srelpath[5]), "recentProjectInfo")
    notifications.notify("project synced")
end

return script
