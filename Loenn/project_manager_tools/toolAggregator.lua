local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local logging = require("logging")
local v = require("utils.version_parser")
local meta = require("meta")

local importers = {}
local supportedLonnVersion = v("0.7.10")
local currentLonnVersion = meta.version

local function safeAddImporter(modname)
    pUtils.insertOrLog(importers, "failed to require project_manager_tools." .. modname,
        mods.requireFromPlugin("project_manager_tools." .. modname))
end
logging.info("[Loenn Project Manager] Loading Project Management tools")
if supportedLonnVersion >= currentLonnVersion then
    safeAddImporter("manageCampaigns")
    safeAddImporter("manageMaps")
    safeAddImporter("newEmptyProject")
    safeAddImporter("newStandardProject")
    safeAddImporter("openProject")
    safeAddImporter("importAdvancedFgTileset")
    safeAddImporter("importAdvancedBgTileset")
    safeAddImporter("deleteFgTileset")
    safeAddImporter("deleteBgTileset")
    safeAddImporter("resyncOpenProject")
    safeAddImporter("editFgTileset")
    safeAddImporter("editBgTileset")
    safeAddImporter("addRemoteFgTileset")
    safeAddImporter("addRemoteBgTileset")
    safeAddImporter("setMountainPosition")
    safeAddImporter("configureOverworld")
    safeAddImporter("setMountainTextures")
    safeAddImporter("setMountainMusic")
else
    safeAddImporter("versionNotif")
end

return importers
