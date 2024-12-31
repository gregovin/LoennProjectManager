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
    tooltip = "Add or edit an endscreen with one non-animated image that will cover the whole screen",
    parameters = {
        image = "",
        title = "",
        music = "",
    },
    tooltips = {
        image = "The image to use for the endscreen. Note: images will be autoscalled to fit the screen.",
        title =
        "Dialog key for the title to use for the endscreen, leave blank for no title. Use \"default\" to get the default key",
        music = "Music event key for the endscreen, if you want to use non-default music"
    },
    fieldInformation = {
        image = {
            fieldType = "loennProjectManager.filePath",
            extension = "png"
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
        "image", "music", "title"
    },
}
local screenWidth = 1920
local screenHeight = 1080
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
        atlas = atlas or fileSystem.joinpath("Endscreens", projectDetails.username, projectDetails.campaign)
        local l = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "Layers" })
        local img = nil
        local has_ui = false
        for i, layer in ipairs(l) do
            if layer["Type"] == "layer" then
                if img or #layer["Images"] > 1 then
                    error("Current endscreen is not simple and cannot be modified with this tool")
                end
                img = layer["Images"][1]
            end
            if layer["Type"] == "ui" then
                has_ui = true
            end
        end
        if img then
            script.parameters.image = pUtils.passIfFile(fileSystem.joinpath(modsDir, projectDetails.name, "Graphics",
                "Atlases", atlas, img .. ".png")) or ""
        else
            script.parameters.image = ""
        end
        oldImg = script.parameters.image
        script.parameters.music = metadataHandler.getNestedValueOrDefault({ "CompleteScreen", "MusicBySide",
            metadataHandler.side })
        script.parameters.title = metadataHandler.getNestedValue({ "CompleteScreen", "Title", sideNames
            [metadataHandler.side] }) or (has_ui and "default") or ""
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
    if not pUtils.isPng(args.image) then
        logging.warning(string.format("Cannot use " .. args.image .. " as an endscreen, it is not a png"))
        notifications.notify("Selected image is not a real png")
        return
    end
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
            notifications.notify("Could not create endscreens directory")
            return
        end
    end
    fileTarget = fileSystem.joinpath(fileTarget, fileSystem.filename(args.image))
    if args.image == oldImg and oldImg == "" then
        notifications.notify("Previous and new image are both null, cannot update")
        return
    end
    if args.image ~= "" and args.image ~= oldImg then --if we have a new image set functions to copy/uncopy it
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
    if oldImg ~= "" and args.image ~= oldImg then --if there is an old image make functions to delete it
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
                error(string.format("Could not recover endscreen %s due to the following error:\n%s", args.tileset,
                    message))
            end
            return true
        end
    end
    local dataBefore = utils.deepcopy(metadataHandler.loadedData)
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Atlas" }, string.gsub(atlas, "\\", "/"))
    --determine the correct scaling
    -- see http://www.libpng.org/pub/png/spec/1.2/PNG-Structure.html for the png spec
    -- A png starts with an 8 byte magic header(checked in pUtils.isPng)
    -- Then a series of chunks
    -- The first chunk has a known data format. Specifically, the first 24 bytes of a png are
    -- HHHHHHHHFFFFFFFFWWWWHHHH
    local scale = 1
    local test, message = io.open(args.image, "rb")
    if test then
        local full_header = test:read(24)
        test:close()
        local w1, w2, w3, w4 = string.byte(full_header, 17, 20) --read the 4 byte integer width(note: big endian)
        local normal_width = w4 + w3 * 256 + w2 * 65536 + w1 * 16777216
        local h1, h2, h3, h4 = string.byte(full_header, 21, 24) --read the 4 byte integer height(note: big endian)
        local normal_height = h4 + h3 * 256 + h2 * 65536 + h1 * 16777216
        local wr = screenWidth / normal_width
        local hr = screenHeight / normal_height
        if wr < hr then
            scale = wr
        else
            scale = hr
        end
    end
    metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers" },
        { {
            Type = "layer",
            Images = { fileSystem.stripExtension(fileSystem.filename(args.image)) },
            Scale = scale,
            Alpha = 1.0,
        } })
    if args.music ~= "" then
        metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "MusicBySide",
            metadataHandler.side }, args.music)
    end
    if args.title ~= "" then
        local tset = nil
        local fset = nil
        if args.title ~= "default" then
            tset = args.title
            fset = args.title .. "_FULLCLEAR"
        end
        metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Layers", 2 }, { Type = "ui" })
        metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Title", sideNames
            [metadataHandler.side] }, tset)
        if metadataHandler.side == 1 then
            metadataHandler.setNestedIfNotDefault({ "CompleteScreen", "Title", "FullClear" }, fset)
        end
    end
    local dataAfter = utils.deepcopy(metadataHandler.loadedData)
    metadataHandler.update({})
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
