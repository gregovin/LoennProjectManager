local mods = require("mods")
local tilesetHandler = mods.requireFromPlugin("libraries.tilesetHandler")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local utils = require("utils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local logging = require("logging")
local notifications = require("ui.notification")
local history = require("history")
local state = require("loaded_state")
local fallibleSnapshot = mods.requireFromPlugin("libraries.fallibleSnapshot")
local celesteEnums = require("consts.celeste_enums")

local selTilesetName
local postscript = {
    name = "editBgTileset2",
    displayName = "Edit Bg Tileset",
    tooltip = "Edit a Background tileset for this campaign",
    verb = "accept",
    parameters = {
        sound = 0,
        ignores = {},
        template = "",
        customMask = "",
    },
    tooltips = {
        sound = "The sound to play when this tile is stepped on",
        ignores =
        "Which tilesets this tile should ignore. Tilesets selected will be treated as air when drawing this tileset",
        template = "Which template to use, or the name of the custom template for this tileset",
        customMask =
        "The mask to apply for this tileset or template. May overide copy mask.\nIf you are instatiating a template, copy the bit that goes between the <tileset> tags here"
    },
    fieldInformation = {
        sound = {
            fieldType = "integer",
            options = celesteEnums.tileset_sound_ids
        },
        ignores = {
            fieldType = "loennProjectManager.multiselect",
            multiselectName = "ignores",
            options = {
                { "all", "*" }
            }
        },
        template = { fieldType = "string" },
        customMask = { fieldType = "string" }
    },
    fieldOrder = {
        "sound", "ignores", "copyMask", "template", "customMask"
    }
}
local projectDetails
local prescript = {
    name = "editBgTileset",
    displayName = "Edit Bg Tileset",
    toolTip = "Edit a Background tileset",
    layer = "background",
    verb = "edit",
    parameters = {
        tileset = ""
    },
    tooltips = {
        tileset = "The tileset to edit"
    },
    fieldInformation = {
        tileset = {
            fieldType = "string",
            options = {}
        }
    },
    nextScript = postscript
}

function prescript.prerun()
    projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        local tops = {}
        for name, t in pairs(tilesetHandler.bgTilesets) do
            if not tilesetHandler.isVanilla(t.path) then
                table.insert(tops, { name, name })
            end
        end
        table.sort(tops, function(a, b)
            return a[1] < b[1]
        end)
        prescript.fieldInformation.tileset.options = tops
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

function prescript.run(args)
    projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    selTilesetName = args.tileset
    local tileset = tilesetHandler.bgTilesets[selTilesetName]
    postscript.displayName = "Editing " .. selTilesetName
    postscript.parameters.sound = tileset.sound or 0
    postscript.parameters.ignores = tileset.ignores or {}
    if tileset.templateInfo then
        postscript.parameters.template = tileset.templateInfo
        postscript.fieldInformation.template.options = nil
    else
        postscript.parameters.template = tileset.copy or ""
        postscript.fieldInformation.template.options = tilesetHandler.sortedTilesetOpts(tilesetHandler.getTemplates(false))
    end
    if tileset.masks then
        postscript.parameters.customMask = tileset.masks
    else
        postscript.parameters.customMask = ""
    end
end

function postscript.prerun()
    projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        local ignoreOptions = tilesetHandler.sortedTilesetOpts(tilesetHandler.bgTilesets)
        table.insert(ignoreOptions, { "All", "*" })
        postscript.fieldInformation.ignores.options = ignoreOptions
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

function postscript.run(args)
    projectDetails = pUtils.getProjectDetails()
    --error if the state doesn't match
    projectLoader.assertStateValid(projectDetails)
    --determine where the backgroundTiles.xml should be
    local target = tilesetHandler.prepareXmlLocation(false, projectDetails)
    local copyMask = ""
    local templateInfo = ""
    local tilesetDetails = utils.deepcopy(tilesetHandler.bgTilesets[selTilesetName])
    if tilesetHandler.isTileset(args.template, false) then
        copyMask = args.template
    else
        if tilesetDetails.used and tilesetDetails.used > 0 and #args.template == 0 then
            notifications.notify("Cannot remove template name for a template which is being used")
            return
        elseif #args.customMask == 0 then
            notifications.notify("Cannot safely remove custom mask from a template")
            return
        end
        templateInfo = args.template
    end
    local forward = function()
        local success, message = tilesetHandler.editTileset(selTilesetName, false, args.sound, args.ignores, copyMask,
            templateInfo, args.customMask, target)
        if not success then
            logging.warning(string.format("Failed to write to %s due to the following error:\n%s", target, message))
        end
        tilesetHandler.reloadTilesets({ "tilesBg" }, state)
        return success, "Could not write to backgroundTiles.xml due to a filesystem error"
    end
    local backward = function()
        local success, message = tilesetHandler.editTileset(selTilesetName, false, tilesetDetails.sound,
            tilesetDetails.ignores, tilesetDetails.copy, tilesetDetails.templateInfo or "", tilesetDetails.masks or "",
            target)
        if not success then
            logging.warning(string.format("Failed to write to %s due to the following error:\n%s", target, message))
        end
        tilesetHandler.reloadTilesets({ "tilesBg" }, state)
        return success, "Could not write to backgroundTiles.xml due to a filesystem error"
    end
    forward()
    history.addSnapshot(fallibleSnapshot.create(postscript.name, {}, backward, forward))
end

return prescript
