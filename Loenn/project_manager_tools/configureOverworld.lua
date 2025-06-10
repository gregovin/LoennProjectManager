local mods = require("mods")
local utils = require("utils")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local history = require("history")
local logging = require("logging")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

local script = {
    name = "configureOverworldDetails",
    displayName = "Configure Overworld Details",
    tooltip = "Configure overworld effects such as fog and star colors, as well as snow",
    layer = "metadata",
    verb = "apply",
    parameters = {
        showSnow = true,
        fogColors = { "010817", "13203E", "281A35", "010817" },
        starFogColor = "020915",
        starStreamColors = { "000000", "9228e2", "30ffff" },
        starBeltColors1 = { "53f3dd", "53c9f3" },
        starBeltColors2 = { "ab6ffa", "fa70ea" },
        markerIcon = "marker/runBackpack",
    },
    tooltips = {
        showSnow         = "Weather or not to show the snow on the overworld",
        fogColors        =
        "The colors of the fog on the mountain, for each state. 2 colors will be used by the game: the one for the state your custom mountain uses, and the first one (state 0) on the main menu.",
        starFogColor     = "The color of the fog in space.",
        starStreamColors = "The color of the 'streams' visible behind the moon",
        starBeltColors1  =
        "The colors of the small stars rotating around the moon. They are dispatched in 2 \"belts\" that are slightly misaligned between each other.",
        starBeltColors2  =
        "The colors of the small stars rotating around the moon. They are dispatched in 2 \"belts\" that are slightly misaligned between each other.",
        markerIcon = "Which map marker icon to use on the overworld when this map is selected.",
    },
    fieldInformation = {
        showSnow = { fieldType = "boolean" },
        fogColors = {
            fieldType = "loennProjectManager.fixedColorList",
            labels = { "night", "dawn", "day", "moon" }
        },
        starFogColor = {
            fieldType = "color", allowXNAColors = false

        },
        starStreamColors = {
            fieldType = "loennProjectManager.fixedColorList",
            labels = { "Stream 1", "Stream 2", "Stream 3" }
        },
        starBeltColors1 = {
            fieldType = "loennProjectManager.expandableColorList"
        },
        starBeltColors2 = {
            fieldType = "loennProjectManager.expandableColorList"
        },
        markerIcon = {
            fieldType="string",
            options = {"marker/Fall","marker/runBackpack", "marker/runNoBackpack"}
        }
    },
    fieldOrder = { "fogColors", "showSnow", "starFogColor", "starStreamColors", "starBeltColors1", "starBeltColors2" }
}
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.cache:get("metadata")
            script.fieldInformation.markerIcon.options={"marker/Fall","marker/runBackpack", "marker/runNoBackpack"}
            local searchpath = fileSystem.joinpath(modsDir, projectDetails.name,"Graphics","Atlases","Mountain","marker",projectDetails.username,projectDetails.campaign)
            if fileSystem.isDirectory(searchpath) then
                for _,v in ipairs(pUtils.list_dir(searchpath)) do
                    local true_n = string.match(fileSystem.filename(v), "^%D*")
                    if not pUtils.contains(script.fieldInformation.markerIcon.options, true_n) then
                        table.insert(script.fieldInformation.markerIcon.options, "marker/" .. true_n)
                    end
                end
            end
        end
        script.parameters.fogColors = metadataHandler.getNestedValueOrDefault({ "Mountain", "FogColors" })
        script.parameters.showSnow = metadataHandler.getNestedValueOrDefault({ "Mountain", "ShowSnow" })
        script.parameters.starFogColor = metadataHandler.getNestedValueOrDefault({ "Mountain", "StarFogColor" })
        script.parameters.starStreamColors = metadataHandler.getNestedValueOrDefault({ "Mountain", "StarStreamColors" })
        script.parameters.starBeltColors1 = metadataHandler.getNestedValueOrDefault({ "Mountain", "StarBeltColors1" })
        script.parameters.starBeltColors2 = metadataHandler.getNestedValueOrDefault({ "Mountain", "StarBeltColors2" })
        script.parameters.markerIcon = metadataHandler.getNestedValueOrDefault({ "Mountain","MarkerTexture"})
        
    elseif not projectDetails.name then
        error("Cannot find metadata because no project is selected!", 2)
    elseif not projectDetails.username then
        error("Cannot find metadata because no username is selected. This should not happen", 2)
    elseif not projectDetails.campaign then
        error("Cannot find metadata because no campaign is selected!", 2)
    else
        error("Cannot find metadata because no map is selected!", 2)
    end
end

function script.run(args)
    local projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    local dataBefore = utils.deepcopy(metadataHandler.loadedData)
    metadataHandler.setNestedIfNotDefault({ "Mountain", "FogColors" }, args.fogColors)
    metadataHandler.setNestedIfNotDefault({ "Mountain", "ShowSnow" }, args.showSnow)
    metadataHandler.setNestedIfNotDefault({ "Mountain", "StarFogColor" }, args.starFogColor)
    metadataHandler.setNestedIfNotDefault({ "Mountain", "StarStreamColors" }, args.starStreamColors)
    local beltC1 = args.starBeltColors1
    if #beltC1 == 0 then
        beltC1 = "[]"
    end
    local beltC2 = args.starBeltColors2
    if #beltC2 == 0 then
        beltC2 = "[]"
    end
    metadataHandler.setNestedIfNotDefault({ "Mountain", "StarBeltColors1" }, beltC1)
    metadataHandler.setNestedIfNotDefault({ "Mountain", "StarBeltColors2" }, beltC2)
    metadataHandler.setNestedIfNotDefault({ "Mountain","MarkerTexture"}, args.markerIcon)
    local dataAfter = utils.deepcopy(metadataHandler.loadedData)
    local forward = function()
        metadataHandler.loadedData = dataAfter
        local success, result = metadataHandler.update({})
        if not success then
            metadataHandler.loadedData = dataBefore
        end
        return success, "Failed to write metadata!"
    end
    local backward = function()
        metadataHandler.loadedData = dataBefore
        local success, result = metadataHandler.update({})
        if not success then
            metadataHandler.loadedData = dataAfter
        end
        return success, "Failed to write metadata!"
    end
    local success, message = forward()
    if not success then
        logging.warning(message)
        return
    end
    local snap = fallibleSnapshot.create("Configure Overworld", { success = true }, backward, forward)
    history.addSnapshot(snap)
end

return script
