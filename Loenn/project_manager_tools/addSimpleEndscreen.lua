local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")
local notifications = require("ui.notification")
local logging = require("logging")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local safeDelete = mods.requireFromPlugin("libraries.safeDelete")
local history = require("history")
local utils = require("utils")

local oldImg
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
    },
}
local sideNames = { "ASide", "BSide", "CSide" }
local atlas
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        atlas = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Atlas" })
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
        oldImg = script.parameters.image
        local f = pUtils.list_dir(fileSystem.joinpath(modsDir, projectDetails.name, "Graphics", "Atlases", atlas))
        script.parameters.start = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Start" })
        script.parameters.center = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Center" })
        script.parameters.scale = ldata["Scale"] or 1
        script.parameters.alpha = ldata["Alpha"] or 1
        script.parameters.music = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "MusicBySide",
            metadataHandler.side })
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
    local projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    local delOld = function()
        return true
    end
    local copyImg = function()
        return true
    end
    local unDelOld = function()
        return true
    end
    local unCopyImg = function()
        return true
    end
    local delLocal, error
    if not atlas then
        atlas = fileSystem.joinpath("Endscreens", projectDetails.username, projectDetails.campaign)
    end

    local fileTarget = fileSystem.joinpath(modsDir, projectDetails.name, "Graphics",
        "Atlases", atlas)
    if not fileSystem.isDirectory(fileTarget) then
        local success, message = fileSystem.mkpath(fileTarget)
        if not success then
            logging.warning(string.format("Encountered error attempting to create endscreen directory: \n%s", message))
            return
        end
    end
    fileTarget = fileSystem.joinpath(fileTarget, fileSystem.filename(args.image))
    if args.image == oldImg and oldImg == "" then
        notifications.notify("Previous and new image are both blank, cannot update")
        return
    end
    if args.image ~= "" then --if we have a new image set functions to copy/uncopy it
        copyImg = function()
            local success, message = fileSystem.copy(args.image, fileTarget)
            if not success then
                logging.warning(string.format("Failed to copy endscreen file due to the following error:\n%s", error), 1)
            end
            return success, "Failed to copy file"
        end
        unCopyImg = function()
            local success, message = os.remove(fileTarget)
            if not success then
                logging.warning(string.format("Failed to remove endscreen file due to the following error:\n%s", error),
                    1)
            end
            return success, "Failed to delete file"
        end
    end
    if oldImg ~= "" then --if there is an old image make functions to delete it
        delOld = function()
            delLocal, error = safeDelete.revdelete(oldImg)
            if error then
                logging.warning(string.format("Failed to remove file due to a following error:\n%s", error), 1)
                return false, "Failed to remove old file"
            end
            return true
        end

        unDelOld = function()
            local success, message = os.rename(delLocal, oldImg)
            if not success then
                error(string.format("Could not recover tileset %s due to the following error:\n%s", args.tileset, message))
            end
            return true
        end
    end
    local dataBefore = utils.deepcopy(metadataHandler.loadedData)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Atlas" }, atlas)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Start" }, args.start)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Center" }, args.center)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers" },
        { {
            Type = "layer",
            Images = string.format("[\"%s\"]", fileSystem.stripExtension(fileSystem.filename(args.image)))
        } })
    if args.music ~= "" then
        metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "MusicBySide",
            metadataHandler.side }, args.music)
    end
    if args.tile ~= "" then
        if args.title ~= "defualt" then
            metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Title", sideNames
                [metadataHandler.side] }, args.title)
        end
        metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers", 2 }, { Type = "ui" })
    end
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers", 1, "Scale" }, args.scale)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers", 1, "Alpha" }, args.alpha)
    local dataAfter = utils.deepcopy(metadataHandler.loadedData)
    local redoMetadata = function()
        metadataHandler.loadedData = dataAfter
        local success, result = metadataHandler.update({})
        if not success then
            metadataHandler.loadedData = dataBefore
        end
        return success, "Failed to write metadata!"
    end
    local undoMetadata = function()
        metadataHandler.loadedData = dataBefore
        local success, result = metadataHandler.update({})
        if not success then
            metadataHandler.loadedData = dataAfter
        end
        return success, "Failed to write metadata!"
    end
    local success, message = redoMetadata()
    if not success then
        notifications.notify(message)
        return
    end
    local success, message = delOld()
    if not success then
        notifications.notify(message)
        success, message = undoMetadata()
        if not success then
            notifications.notify(message)
        end
        return
    end
    success, message = copyImg()
    if not success then
        notifications.notify(message)
        success, message = unDelOld()
        if not success then
            notifications.notify(message)
            return
        end
        success, message = undoMetadata()
        if not success then
            notifications.notify(message)
        end
        return
    end
    local oldSnap = fallibleSnapshot.create("Delete old image", {}, unDelOld, delOld)
    local imgSnap = fallibleSnapshot.create("Copy new image", {}, unCopyImg, copyImg)
    local metaSnap = fallibleSnapshot.create("Update metadata", {}, undoMetadata, redoMetadata)
    history.addSnapshot(fallibleSnapshot.multiSnapshot("Update Endscreen", { metaSnap, oldSnap, imgSnap }))
end

return script
