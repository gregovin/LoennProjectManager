local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local logging = require("logging")
local projectLoader=mods.requireFromPlugin("libraries.projectLoader")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local script = {
    name = "manageCampaigns",
    displayName = "Choose Campaign",
    tooltip = "Select or create a campaign for your project",
    layer="project",
    tooltips = {
        campaignName = "The name for your campaign. Select from the list or enter a new entry to create a new campaign. \n Must be a valid portable filename",
    },
    parameters = {
        campaignName = "",
    },
    fieldInformation = {
        campaignName = {
            fieldType = "loennProjectManager.fileName",
            options = {},
            editable = true
        },
    }
}
function script.prerun()
    script.fieldInformation.campaignName.options=settings.get("campaigns",{},"recentProjectInfo")
end
function script.run(args)
    local projectDetails = {
        projectName=settings.get("name",nil,"recentProjectInfo"),
        username=settings.get("username",nil),
        campaigns= settings.get("campaigns",{},"recentProjectInfo")
    }
    if projectDetails.projectName and projectDetails.username then
        local target= fileSystem.joinpath(modsDir,projectDetails.projectName,"Maps",projectDetails.username,args.campaignName)
        if $(projectDetails.campaigns):contains(args.campaignName) then
            projectLoader.loadCampaign(target)
        else
            projectLoader.newCampaign(targete,projectDetails)
        end
        projectLoader.clearMetadataCache()
    elseif projectDetails.projectName then
        notifications.notify("No username set! Select or Create a project amd try again.", 10)
        logging.warning(string.format("Failed to create campaign %s because no username has been set",args.campaignName))
    else
        notifications.notify("No project selected! Select or Create a project amd try again.", 10)
        logging.warning(string.format("Failed to create campaign %s because no project has been set",args.campaignName))
    end
end

return script