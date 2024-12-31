local mods = require("mods")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local settings = mods.requireFromPlugin("libraries.settings")
local notifications = require("ui.notification")
local logging = require("logging")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local osUtils = require("utils.os")
local os = require("os")

local script = {
    name = "zipMod",
    displayName = "Zip Mod",
    tooltip = "Export your mod as a zip",
    layer = "project",
    parameters = {
        outputDir = "",
    },
    tooltips = {
        outputDir = "The directory you want the zip file to be in"
    },
    fieldInformation = {
        outputDir = {
            fieldType = "loennProjectManager.filePath",
            requireDir = true
        }
    }
}
function script.prerun()
    if not settings.get("name", nil, "recentProjectInfo") then
        error("Cannot zip empty mod")
    end
end

local zip_targets = {
    "everest.yaml",
    "DecalRegistry.xml",
    "credits.txt",
    "CollabUtils2CollabID.txt",
    "Tutorials",
    "Mountain",
    "MaxHelpingHandWipes",
    "Maps",
    "Graphics",
    "Dialog",
    "Audio",
    "Assets",
    fileSystem.joinpath("Code", "build"),
    "bin"
}
function script.run(args)
    local cur_os = osUtils.getOS()
    local mod_name = settings.get("name", nil, "recentProjectInfo")
    local mod_locale = fileSystem.joinpath(modsDir, mod_name)
    local zstr = ""
    for _, v in ipairs(zip_targets) do
        local target = fileSystem.joinpath(mod_locale, v)
        if fileSystem.isFile(target) or fileSystem.isDirectory(target) then
            zstr = zstr .. " " .. v
        end
    end
    if cur_os == "Linux" then
        local success = os.execute("cd " .. mod_locale .. "; zip -r \"" ..
            fileSystem.joinpath(args.outputDir, mod_name) .. ".zip\"" .. zstr)
        if not success then
            notifications.notify("Packaging failed")
            logging.info("Packaging " .. mod_locale ..
                " encountered a failure. This likely means that the zip command is not installed or there is some permision issue")
        end
    elseif cur_os == "Windows" then
        local success = os.execute("cd " .. mod_locale ..
            "& tar -a -c -f \"" .. fileSystem.joinpath(args.outputDir, mod_name) .. ".zip\"" .. zstr)
        if not success then
            notifications.notify("Packaging failed")
            logging.info("Packaging " ..
                mod_locale ..
                " encountered a failure. This likely means that there is some permision issue, or if you are on an older windows platform the tar command is not installed.")
        end
    elseif cur_os == "OS X" then
        local success = os.execute("cd " .. mod_locale .. "; zip -xr \"" ..
            fileSystem.joinpath(args.outpod_name) .. ".zip\"" .. zstr)
        if not success then
            notifications.notify("Packaging failed")
            logging.info("Packaging " ..
                mod_locale .. " encountered a failure. This likely means that there is some permision issue")
        end
    end
end

return script
