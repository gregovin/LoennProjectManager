local mods = require("mods")
local pluginLoader = require("plugin_loader")
local utils = require("utils")
local logging = require("logging")
local configs = require("configs")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local notifications = require("ui.notification")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

local script = {
    name = "ReskinEntity",
    displayName = "Reskin Entity",
    tooltip = "Reskin a reskinnable entity",
    paramaters = {
        entity = "Jump Through"
    },
    tooltips = {
        entity = "The entity to reskin"
    },
    fieldInformation = {
        entity = {
            fieldType = "string",
            options = {
            }
        }
    }
}
local reskinners = {}
local function loadReskinner(filename)
    local modFolder = string.sub(filename, 2, string.find(filename, "/") - 2)
    local modName = utils.humanizeVariableName(modFolder):gsub(" Zip", "")
    local pathNoExt = utils.stripExtension(filename)
    local filenameNoExt = utils.filename(pathNoExt, "/")

    local handler = utils.rerequire(pathNoExt)
    local name = handler.name or filenameNoExt
    handler.__mod = modName
    if configs.debug.logPluginLoading then
        logging.info("Loaded script '" .. name .. "' [" .. modName .. "] " .. " from: " .. filename)
    end
    reskinners[name] = handler
    table.insert(script.fieldInformation.entity.options, name)
    return name
end
pluginLoader.loadPlugins(mods.findPlugins("reskinners"), nil, loadReskinner, false)
local destination = ""
local entityName = "Jump Through"
local fileSkin = {
    displayName = "Reskin Entity",
    paramaters = {
        source = ""
    },
    tooltips = {
        source = "The file to use as a skin"
    },
    fieldInformation = {
        source = {
            fieldType = "loennProjectManager.filePath",
            extension = "png"
        }
    }
}
function fileSkin.run(args)
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign then
        local isPng, logMsg, notifMsg = pUtils.isPng(args.source)
        if not isPng then
            logging.warning(logMsg)
            notifications.notify(notifMsg)
            return
        end
        if reskinners[entityName].allow_many then
            
        else
        
        end
    else
        notifications.notify("No campaign loaded, could not reskin entity")
    end
end

local folderSkin = {
    displayName = "Reskin Entity",
    paramaters = {
        source = ""
    },
    tooltips = {
        source = "The folder containing the animation to use as a skin"
    },
    fieldInformation = {
        source = {
            fieldType = "loennProjectManager.filePath",
            requireDir = true
        }
    }
}
function script.run(args)

end

return script
