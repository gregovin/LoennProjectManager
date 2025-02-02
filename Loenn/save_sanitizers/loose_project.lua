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
    if not string.find(filename, modsDir, 1, true) or fileSystem.fileExtension(filename) ~= "bin" then
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
    elseif #srelpath ~= 5 or srelpath[2] ~= "Maps" then
        sceneHandler.sendEvent("loennProjectManagerBadStructure", filename)
    end
    logging.info("Hello world")
end

return sanitizer
