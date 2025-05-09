local mods = require("mods")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local utils = require("utils")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local history = require("history")
local logging = require("logging")

local detailScript = {
    name = "setMountainPos",
    displayName = "Set Mountain Positon",
    layer = "metadata",
    verb = "apply",
    tooltip =
    "Modify where your map appears in the overworld, as well as the overworld state when your map is selected.\nSee the Overworld Customisation page on the everest api wiki for more info on how to use this",
    parameters = {
        idlePosition = { 0, 0, 0 },
        idleTarget = { 0, 0, 0 },
        selectPosition = { 0, 0, 0 },
        selectTarget = { 0, 0, 0 },
        zoomPosition = { 0, 0, 0 },
        zoomTarget = { 0, 0, 0 },
        cursor = { 0, 0, 0 },
        state = 0,
        showCore = false,
        rotate = false
    },
    tooltips = {
        idlePosition = "The position of the camera durring level selection on the overworld.",
        idleTarget = "The position the camera is looking at durring level selection",
        selectPosition = "The position of the camera when this map is selected.",
        selectTarget = "The target of the camera when this map is selected",
        zoomPosition = "The position of the camera when zooming into the map when pressing start",
        zoomTarget = "The position of the camera target when zooming into the map when pressing start",
        cursor = "The location of the madeline cursor on the mountain",
        state = "The lighting of the mountain",
        showCore = "Whether or not the core heart is shown on the mountain",
        rotate = "Wether or not the camera should rotate oround the mountian"
    },
    fieldInformation = {
        idlePosition = { fieldType = "loennProjectManager.position3d" },
        idleTarget = { fieldType = "loennProjectManager.position3d" },
        selectPosition = { fieldType = "loennProjectManager.position3d" },
        selectTarget = { fieldType = "loennProjectManager.position3d" },
        zoomPosition = { fieldType = "loennProjectManager.position3d" },
        zoomTarget = { fieldType = "loennProjectManager.position3d" },
        cursor = { fieldType = "loennProjectManager.position3d" },
        state = {
            fieldType = "integer",
            options = { { "night", 0 }, { "dawn", 1 }, { "day", 2 }, { "moon", 3 } }
        },
        showCore = { fieldType = "boolean" },
        rotate = { fieldType = "boolean" }
    },
    fieldOrder = {
        "idlePosition", "idleTarget", "selectPosition", "selectTarget", "zoomPosition", "zoomTarget", "cursor", "state",
        "showCore", "rotate"
    }
}
local initScript = {
    name = "setMountainPos",
    displayName = "Set Mountain Position",
    layer = "metadata",
    tooltip =
    "Modify where your map appears in the overworld, as well as the overworld state when your map is selected.\nSee the Overworld Customisation page on the everest api wiki for more info on how to use this",
    parameters = {
        copy = "",
    },
    tooltips = {
        copy = "The map whose details to copy. Leave unset to specify the details manually",
    },
    fieldInformation = {
        copy = {
            fieldType = "string",
            options = { "Prologue", "Forsaken City", "Old Site", "Celestial Resort", "Golden Ridge", "Mirror Temple", "Reflection", "The Summit", "Epilogue", "Core", "Farewell" }
        },
    },
    fieldOrder = { "copy", "overideOtherConfig" }
}
local function arrayIfyList(ls)
    return "[" .. pUtils.listToString(ls, ", ") .. "]"
end
function initScript.run(args)
    metadataHandler.readMetadata(pUtils.getProjectDetails())
    if args.copy ~= "" then
        local appliedConf = metadataHandler.vanillaMountainConfig[args.copy]
        initScript.nextScript = nil
        local newData = {
            ["Mountain"] = {
                ["Idle"] = {
                    ["Position"] = appliedConf.idle.position,
                    ["Target"] = appliedConf.idle.target
                },
                ["Select"] = {
                    ["Position"] = appliedConf.select.position,
                    ["Target"] = appliedConf.select.target
                },
                ["Zoom"] = {
                    ["Position"] = appliedConf.zoom.position,
                    ["Target"] = appliedConf.zoom.target
                },
                ["Cursor"] = appliedConf.cursor,
                ["State"] = appliedConf.state,
                ["ShowCore"] = appliedConf.showCore,
                ["Rotate"] = appliedConf.rotate
            }
        }
        local dataBefore = utils.deepcopy(metadataHandler.loadedData)
        local forward = function()
            local success, message = metadataHandler.update(newData)
            if not success then
                metadataHandler.loadedData = dataBefore
            end
            return success, "Failed to write metadata"
        end
        local backward = function()
            metadataHandler.loadedData = dataBefore
            local success, message = metadataHandler.write()
            if not success then
                metadataHandler.update(newData)
            end
            return success, "Failed to write metadata"
        end
        local success, message = forward()
        if not success then
            metadataHandler.loadedData = dataBefore
            logging.warning(message)
            return
        end
        local snap = fallibleSnapshot.create("Set Position", { success = true }, backward, forward)
        history.addSnapshot(snap)
    else
        initScript.nextScript = detailScript
    end
end

function detailScript.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        detailScript.parameters.idlePosition = metadataHandler.getNestedValue({ "Mountain", "Idle", "Position" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.idleTarget = metadataHandler.getNestedValue({ "Mountain", "Idle", "Target" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.selectPosition = metadataHandler.getNestedValue({ "Mountain", "Select", "Position" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.selectTarget = metadataHandler.getNestedValue({ "Mountain", "Select", "Target" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.zoomPosition = metadataHandler.getNestedValue({ "Mountain", "Zoom", "Position" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.zoomTarget = metadataHandler.getNestedValue({ "Mountain", "Zoom", "Target" }) or
            { 0.0, 0.0, 0.0 }
        detailScript.parameters.cursor = metadataHandler.getNestedValue({ "Mountain", "Cursor" }) or { 0.0, 0.0, 0.0 }
        detailScript.parameters.state = metadataHandler.getNestedValue({ "Mountain", "State" }) or 0
        detailScript.parameters.showCore = metadataHandler.getNestedValue({ "Mountain", "ShowCore" }) or false
        detailScript.parameters.rotate = metadataHandler.getNestedValue({ "Mountain", "Rotate" }) or false
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

function detailScript.run(args)
    projectLoader.assertStateValid(pUtils.getProjectDetails())
    local dataBefore = utils.deepcopy(metadataHandler.loadedData)
    local newData = {
        ["Mountain"] = {
            ["Idle"] = {
                ["Position"] = args.idlePosition,
                ["Target"] = args.idleTarget
            },
            ["Select"] = {
                ["Position"] = args.selectPosition,
                ["Target"] = args.selectTarget
            },
            ["Zoom"] = {
                ["Position"] = args.zoomPosition,
                ["Target"] = args.zoomTarget
            },
            ["Cursor"] = args.cursor,
            ["State"] = args.state,
            ["ShowCore"] = args.showCore,
            ["Rotate"] = args.rotate
        }
    }
    local success, reason = metadataHandler.update(newData)
    if not success then
        metadataHandler.loadedData = dataBefore
        logging.warning("Failed to write metadata")
        return
    end
    local dataAfter = utils.deepcopy(metadataHandler.loadedData)
    local forward = function()
        metadataHandler.loadedData = dataAfter
        local success, reason = metadataHandler.write()
        if not success then
            metadataHandler.loadedData = dataBefore
        end
        return success, "Failed to write metadata"
    end
    local backward = function()
        metadataHandler.loadedData = dataBefore
        local success, reason = metadataHandler.write()
        if not success then metadataHandler.loadedData = dataAfter end
        return success, "Failed to write metadat"
    end
    local snap = fallibleSnapshot.create("Set Position", { success = true }, backward, forward)
    history.addSnapshot(snap)
end

return initScript
