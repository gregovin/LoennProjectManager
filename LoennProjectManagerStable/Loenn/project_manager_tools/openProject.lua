local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local projectLoader= mods.requireFromPlugin("libraries.projectLoaders")
local p_utils=mods.requireFromPlugin("libraries.projectUtils")
local logging = require("logging")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local script = {
    name = "openProject",
    displayName = "Open Project",
    tooltip = "Open a pre-existing project",
    tooltips = {
        modIdentifier = "The identifier for mod. This will be the top level folder your mod will be saved in",
        username = "Your username",
    },
    parameters = {
        projectLocation=""
    },
    fieldInformation = {
        projectLocation = {
            fieldType = "loennProjectManager.filePath",
            require_dir = true,
            location = modsDir
        },
    },
}

function script.run(args)
    logging.info("loading project at "..args.projectLocation)
    -- the path should be project/maps/username/{campaigns}

    -- so first we get a list of potential usernames. We expect there to be exactly 1
    local target = fileSystem.joinpath(args.projectLocation,"Maps")
    local spath = fileSystem.splitpath(args.projectLocation)
    local usernames = p_utils.list_dir(target)
    if #usernames == 1 then
        settings.set("name",spath[#spath],"recentProjectInfo")
        projectLoader.clearMetadataCache()
        local pusername=usernames[1]
        settings.set("username",pusername)
        target=fileSystem.joinpath(target,pusername)
        local campaigns = p_utils.list_dir(target)
        settings.set("campaigns",campaigns,"recentProjectInfo")
        if #campaigns == 1 then
            local pcampaign = campaigns[1]
            settings.set("SelectedCampaign",pcampaign,"recentProjectInfo")
            target= fileSystem.joinpath(target,pcampaign)
            projectLoader.loadCampaign(target,pcampaign)
        elseif #campaigns>1 then
            settings.set("maps",{},"recentProjectInfo")
            notifications.notify("Project initialized. Select a campaign to continue")
        else
            settings.set("maps",{},"recentProjectInfo")
            notifications.notify("Project initialized. Create a campaign to continue")
        end
    else
        notifications.notify("Project has invalid structure, failed to load")
        logging.warning(string.format("Attempted to load project at %s, but the project did not have a single unique username. This likely means the project is non-standard and cannot be loaded at this time",args.projectLocation))
    end
end

return script