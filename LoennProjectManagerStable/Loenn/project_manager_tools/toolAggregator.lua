local mods = require("mods")
local logging = require("logging")
local importers = {}
table.insert(importers,mods.requireFromPlugin("project_manager_tools.manageCampaigns"))
table.insert(importers,mods.requireFromPlugin("project_manager_tools.manageMaps"))
table.insert(importers,mods.requireFromPlugin("project_manager_tools.newEmptyProject"))
table.insert(importers,mods.requireFromPlugin("project_manager_tools.newStandardProject"))
table.insert(importers,mods.requireFromPlugin("project_manager_tools.openProject"))

return importers