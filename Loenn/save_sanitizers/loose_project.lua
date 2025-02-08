local mods = require("mods")
local logging = require("logging")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")

local sceneHandler = require("scene_handler")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

local sanitizer = {

}

-- Disable for specific filenames, should not be persisted
sanitizer.disableEventFor = {}

function sanitizer.beforeSave(filename, state)
    local start = string.find(filename, modsDir, 1, true)
    if not start or start ~= 1 or fileSystem.fileExtension(filename) ~= "bin" then
        return false
    end

    if sanitizer.disableEventFor[filename] then
        return
    end
    local rpth = pUtils.pathDiff(modsDir, filename)
    local srelpath = fileSystem.splitpath(rpth)
    if #srelpath == 1 then
        --trigger ui nonsense
        sceneHandler.sendEvent("loennProjectManagerLooseBinEvent", filename)
        return
    elseif #srelpath ~= 5 or srelpath[2] ~= "Maps" then
        sceneHandler.sendEvent("loennProjectManagerBadStructure", filename)
        return
    end
    local projectDetails = pUtils.getProjectDetails()
    if not (projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.username
            and fileSystem.joinpath(modsDir, projectDetails.name, "Maps", projectDetails.username,
                projectDetails.campaign, projectDetails.map .. ".bin") == filename) then
        sceneHandler.sendEvent("loennProjectManagerResync", filename)
    end
end

return sanitizer
