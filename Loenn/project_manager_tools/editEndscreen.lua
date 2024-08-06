local mods = require("mods")
local metadataScreenWindow = mods.requireFromPlugin("ui.windows.metadataScreenWindow")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")

local script = {
    name = "editEndscreen",
    displayName = "Edit Endscreen",
    layer = "metadata",
    tooltip = "Modify the endscreen",
}
function script.run()
    if not projectLoader.cacheValid then
        projectLoader.loadMetadataDetails(pUtils.getProjectDetails())
    end
    metadataScreenWindow.editMetadataScreen({ map = {}, files = {} }, "Endscreen Window")
end

return script
