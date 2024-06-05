local mods = require("mods")
local metadataScreenWindow = mods.requireFromPlugin("ui.windows.scriptMetadataScreenWindow")

local script = {
    name = "editEndscreen",
    displayName = "Edit Endscreen",
    layer = "metadata",
    tooltip = "Modify the endscreen",
}
function script.run()
    metadataScreenWindow.editMetadataScreen({}, "Endscreen Window")
end

return script
