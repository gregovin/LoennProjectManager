-- modified from loenn scripts' script tool, licensed under MIT
local state = require("loaded_state")
local configs = require("configs")
local toolUtils = require("tool_utils")
local modHandler = require("mods")
local logging = require("logging")
local scriptParameterWindow = modHandler.requireFromPlugin("ui.windows.scriptParameterWindow")
local scriptsLibrary = modHandler.requireFromPlugin("libraries.scriptsLibrary")
local notifications = require("ui.notification")
local viewportHandler = require("viewport_handler")
local drawing = require("utils.drawing")
local importers = modHandler.requireFromPlugin("project_manager_tools.toolAggregator")
local safeDelete = modHandler.requireFromPlugin("libraries.safeDelete")
local colors = require("consts.colors")
local v = require("utils.version_parser")

local tool = {}

tool._type = "tool"
tool.name = "project_manager"
tool.group = "z"
tool.image = nil
tool.layer = "project"
tool.validLayers = {
    "project",
    "foreground",
    "background",
    "metadata"
}

-- the positions of all currently active scripts (aka those with the property window open), used for rendering previews
---x:number, y:number color:table[3]
local activeScriptPositions = {}

local scriptLocationPreviewColors = {
    { 1, 0, 0 },
    { 0, 1, 0 },
    { 0, 0, 1 },
    { 1, 1, 0 },
    { 1, 0, 1 },
    { 0, 1, 1 },
    { 1, 1, 1 },
}

function tool.reset(load)
    tool.currentScript = ""
    tool.scriptsAvailable = {}
    tool.scriptsAvailable["project"] = {}
    tool.scriptsAvailable["foreground"] = {}
    tool.scriptsAvailable["background"] = {}
    tool.scriptsAvailable["metadata"] = {}
    tool.scripts = {}
    safeDelete.startup()
    if load then
        tool.load()
        toolUtils.sendLayerEvent(tool, tool.layer)
    end
end

tool.reset(false)

local function addScript(name, displayName, tooltip, layer)
    table.insert(tool.scriptsAvailable[layer], {
        name = name,
        displayName = (displayName or name),
        tooltipText = tooltip,
    })
end

function tool.execScript(script, args, ctx)
    ctx = ctx or {}

    ctx.mouseX = ctx.mouseX or 0
    ctx.mouseY = ctx.mouseY or 0

    if script.run then
        script.run(args)
    end
end

function tool.safeExecScript(script, args, contextTable)
    local success, message = pcall(tool.execScript, script, args, contextTable)
    if not success then
        logging.warning(string.format("Failed to run script!"))
        logging.warning(debug.traceback(message))
        notifications.notify("Failed to run script!")
    end
    if script.nextScript then
        tool.useScript(script.nextScript, contextTable)
    end
end

local function indexofPos(table, pos)
    for i, value in ipairs(table) do
        if pos.x == value.x and pos.y == value.y then
            return i
        end
    end

    return -1
end
function tool.useScript(script, contextTable)
    if type(script) == "string" then
        script = tool.scripts[script]
    end

    if not script then return end
    if script.prerun then
        local success, message = pcall(script.prerun)
        if not success then
            logging.warning(string.format("Failed to ititialize script!"))
            logging.warning(debug.traceback(message))
            notifications.notify(message, 10)
            return
        end
    end
    if script.parameters then
        local storedPos = {
            x = contextTable.mouseMapX or 0,
            y = contextTable.mouseMapY or 0,
            color = scriptLocationPreviewColors[((#activeScriptPositions) % (#scriptLocationPreviewColors)) + 1]
        }

        table.insert(activeScriptPositions, storedPos)
        scriptParameterWindow.createContextMenu(script, tool.safeExecScript, contextTable, function()
            table.remove(activeScriptPositions, indexofPos(activeScriptPositions, storedPos))
        end)
    else
        tool.safeExecScript(script, {}, contextTable or {})
    end
end

function tool.setLayer(layer)
    if layer ~= tool.layer or not tool.scriptsAvailable then
        tool.layer = layer

        toolUtils.sendLayerEvent(tool, layer)
    end
end

function tool.setMaterial(material)
    if type(material) ~= "number" then
        tool.currentScript = material
    end
end

function tool.mouseclicked(x, y, button, istouch, pressed)
    local actionButton = configs.editor.toolActionButton

    if button == actionButton then
        local mx, my = viewportHandler.getMapCoordinates(x, y or 0)

        tool.useScript(tool.currentScript, {
            mouseX = x,
            mouseY = y,
            mouseMapX = mx,
            mouseMapY = my,
        })
    end
end

function tool.getMaterials(layer)
    return tool.scriptsAvailable[layer]
end

local function finalizeScript(handler, name)
    handler.scriptsTool = tool

    if configs.debug.logPluginLoading then
        logging.info("Loaded project management tool '" .. name)
    end

    addScript(name, handler.displayName, handler.tooltip, handler.layer)
    tool.scripts[name] = handler

    return name
end

function tool.loadScripts()
    for i, importer in ipairs(importers) do
        finalizeScript(importer, importer.name)
    end
end

function tool.load()
    tool.loadScripts()
end

local function drawPreviewRect(px, py)
    love.graphics.rectangle("line", px - 2.5, py - 2.5, 5, 5)
    love.graphics.rectangle("line", px, py, .1, .1)
end

function tool.draw()
    local room = state.getSelectedRoom()

    if room then
        local px, py = scriptsLibrary.safeGetRoomCoordinates(room)

        drawing.callKeepOriginalColor(function()
            -- draw preview for the currently held script
            viewportHandler.drawRelativeTo(room.x, room.y, function()
                love.graphics.setColor(colors.brushColor)
                drawPreviewRect(px, py)
            end)

            -- draw previews for any active scripts
            viewportHandler.drawRelativeTo(0, 0, function()
                for i, pos in ipairs(activeScriptPositions) do
                    love.graphics.setColor(pos.color)
                    drawPreviewRect(pos.x, pos.y)
                end
            end)
        end)
    end
end

return tool
