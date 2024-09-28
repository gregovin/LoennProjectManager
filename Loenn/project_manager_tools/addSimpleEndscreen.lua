local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local notifications = require("ui.notification")
local logging = require("logging")

local script = {
    name = "addSimpleEndscreen",
    displayName = "Add Simple Endscreen",
    layer = "metadata",
    tooltip = "Add or edit an endscreen with one non-animated image",
    parameters = {
        image  = "",
        start  = { 0.0, 0.0 },
        center = { 0.0, 0.0 },
        scale  = 1.0,
        alpha  = 1.0,
        title  = "",
        music  = "",
    },
    tooltips = {
        image = "the image to use for the endscreen",
        start = "the position the image starts with",
        center = "the final position of the image",
        scale = "the scale of the image",
        alpha = "transparency of the image from 0 to 1",
        title =
        "Dialog key for the title to use for the endscreen, leave blank for no title. Use \"default\" to get the default key",
        music = "Music event key for the endscreen, if you want to use non-default music"
    },
    fieldInformation = {
        image = {
            fieldType = "loennProjectManager.filePath",
            extension = "png"
        },
        start = {
            fieldType = "loennProjectManager.position2d"
        },
        center = {
            fieldType = "loennProjectManager.position2d"
        },
        scale = {
            fieldType = "number",
            minimumValue = 0.0,
        },
        alpha = {
            fieldType = "number",
            minimumValue = 0.0,
            maximumValue = 1.0
        },
        title = {
            fieldType = "string",
            validator = function(s)
                return s == "" or (not string.match(s, "[^a-zA-Z0-9_]"))
            end
        },
        music = {
            fieldType = "loennProjectManager.musicKey"
        }
    },
    fieldOrder = {
        "image", "start", "center", "music", "title", "alpha"
    }
}
local warnfolder = false
local sideNames = { "ASide", "BSide", "CSide" }
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        local atlas = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Atlas" })
        local l = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Layers" })
        local img
        local ldata = {}
        for i, layer in ipairs(l) do
            if layer["Type"] == "layer" then
                if img or #layer["Images"] > 1 then
                    notifications.notify("Current endscreen is not simple and cannot be modified with this tool")
                    return
                else
                    img = layer["Images"][1]
                    ldata = layer
                end
            end
        end
        if img then
            script.parameters.image = pUtils.passIfFile(fileSystem.joinpath(modsDir, projectDetails.name, "Graphics",
                "Atlases", atlas, img)) or ""
        else
            script.parameters.image = ""
        end
        local f = pUtils.list_dir(fileSystem.joinpath(modsDir, projectDetails.name, "Graphics", "Atlases", atlas))
        warnfolder = #f > 1
        script.parameters.start = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Start" })
        script.parameters.center = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Center" })
        script.parameters.scale = ldata["Scale"] or 1
        script.parameters.alpha = ldata["Alpha"] or 1
        script.parameters.music = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "MusicBySide" })
            [metadataHandler.side]
        script.parameters.title = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Title", sideNames
            [metadataHandler.side] })
    elseif not projectDetails.name then
        error("Cannot find tilesets because no project is selected!", 2)
    elseif not projectDetails.username then
        error("Cannot find tilesets because no username is selected. This should not happen", 2)
    elseif not projectDetails.campaign then
        error("Cannot find tilesets because no campaign is selected!", 2)
    else
        error("Cannot find tilesets because no map is selected!", 2)
    end
end

function script.run(args)

end

return script
