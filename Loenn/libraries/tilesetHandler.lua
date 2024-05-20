local mods = require("mods")
local settings = mods.requireFromPlugin("libraries.settings")
local xmlHandler = require("lib.xml2lua.xmlhandler.tree")
local xml2lua = require("lib.xml2lua.xml2lua")
local xmlWriter = mods.requireFromPlugin("libraries.xmlWriter")
local utils = require("utils")
local fileSystem = require("utils.filesystem")
local logging = require("logging")
local utf8 = require("utf8")
local mapcoder = require("mapcoder")
local fileLocations = require("file_locations")
local celesteRender = require("celeste_render")
local side_struct = require("structs.side")
local projectUtils = mods.requireFromPlugin("libraries.projectUtils")
local tilesStruct = require("structs.tiles")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")

local handler = {}
---The table of foreground tilesets
---@type {[string]:table}
handler.fgTilesets = {}
---The table of background tilesets
---@type {[string]:table}
handler.bgTilesets = {}
--- A table that goes from ids to names for foreground and background tilesets
handler.revDict = {
    ---@type {[string]:string}
    foreground = {},
    ---@type {[string]:string}
    background = {}
}
---the table of foreground templates
---@type {[string]:table}
handler.fgTemplates = {}
---the table of background templates
---@type {[string]:table}
handler.bgTemplates = {}
handler.fgXml = nil
handler.bgXml = nil
---@type string?
handler.tpath = nil
---@type string[]
local ids_used = { "\"", "&", "'", "<", ">" } -- these are probably all a bad idea to use
---@tpye integer
local curId = 33                      --ascii 33 is !
--adds relevant special characters to ids_used on run
local function addSpecialChars()
    for i = 0x7F, 0xA0 do --this range is control characters
        table.insert(ids_used, utf8.char(i))
    end
    table.insert(ids_used, utf8.char(173))
end
---clears the cached values as needed. Run when the metadata cache is cleared
function handler.clearTilesetCache()
    handler.fgTilesets = {}
    handler.bgTilesets = {}
    handler = {}
    handler.fgXml = nil
    handler.bgXml = nil
    handler.tpath = nil
    handler.revDict = {
        foreground = {},
        background = {}
    }
    handler.fgTemplates = {}
    handler.bgTemplates = {}
    settings.set("foregroundTilesXml", nil, "recentProjectInfo")
    settings.set("backgroundTilesXml", nil, "recentProjectInfo")
    settings.set("animatedTilesets", nil, "recentProjectInfo")
    handler.tpath = nil
    ids_used = { "\"", "&", "'", "<", ">" }
end

---get the tileset table relevant for the value of foreground
---@param foreground boolean weather or not to return the foreground table
---@return { [string]: table }
function handler.getTilesets(foreground)
    if foreground then
        return handler.fgTilesets
    else
        return handler.bgTilesets
    end
end

---get the template table relevant for the value of foreground
---@param foreground boolean
---@return { [string]: table }
function handler.getTemplates(foreground)
    if foreground then
        return handler.fgTemplates
    else
        return handler.bgTemplates
    end
end
---Reload all tilesets
---@param key string which layer to invalidate(tilesFg or tilesBg)
---@param side table the side struct to reload
function handler.reloadTilesets(key, side)
    celesteRender.loadCustomTilesetAutotiler(side)

    -- Invalidate all tile renders
    celesteRender.invalidateRoomCache(nil, key)

    -- Redraw any visible rooms
    local selectedItem, selectedItemType = side.getSelectedItem()

    celesteRender.clearBatchingTasks()
    celesteRender.forceRedrawVisibleRooms(side.map.rooms, side, selectedItem, selectedItemType)
end

local function fixWierdXml(xmlString)
    return string.gsub(xmlString, "<set>%s*<([^>/\"]*)>([^<]*)</%1>%s*<([^>/\"]*)>([^<]*)</%3>%s*</set>",
        "<set %1=\"%2\" %3=\"%4\"/>")
end
---Processes a tileset xml
---@param xmlString string the xmlString to process
---@param foreground boolean when true loads tilesets into the foreground table, otherwise the background table
---@param projectDetails table table of project details
function handler.processTilesetXml(xmlString, foreground, projectDetails)
    if #ids_used == 5 then
        addSpecialChars()
    end
    ---parse the xml!
    local xhandler = xmlHandler:new()
    local parser = xml2lua.parser(xhandler)
    local folders = {}
    local xml = utils.stripByteOrderMark(xmlString)
    local tilesetDir = fileSystem.joinpath(modsDir, projectDetails.name, "Graphics", "Atlases", "Gameplay", "tilesets")
    parser:parse(xml)
    ---prepare some tables and store the xml
    local tilesets = {}
    local templates = {}
    if foreground then
        handler.fgXml = xhandler.root
    else
        handler.bgXml = xhandler.root
    end
    -- loop over all the tilesets!
    local tilesetRoot = xhandler.root.Data.Tileset
    for i, element in ipairs(tilesetRoot) do
        --translate the xml attrs into a table entry
        local id = element._attr.id
        local copy = element._attr.copy
        local ignores = element._attr.ignores or ""
        local path = element._attr.path
        local folder = string.match(path, "(.*/)")
        if folder and fileSystem.isFile(fileSystem.joinpath(tilesetDir, path)) then
            folders[folder] = true
        end
        local displayName = element._attr.displayName
        local sound = element._attr.sound
        local templateInfo = element._attr.templateInfo
        local name = displayName
        if not name then
            name = utils.filename(path, "/") or path
            if not foreground then
                name = string.match(name, "^bg(.*)") or name
            end
            name = utils.humanizeVariableName(name)
        end
        tilesets[name] = {
            id = id,
            copy = copy,
            path = path,
            sound = tonumber(sound) or 0,
            ignores = {},
            templateInfo = templateInfo,
        }
        if element.set then
            tilesets[name].masks = fixWierdXml(xmlWriter.toXml(element.set, "set"))
        end
        for v in string.gmatch(ignores, "[^,]+") do
            tilesets[name].ignores[v] = true
        end
        local revDict = (foreground and handler.revDict.foreground) or handler.revDict.background
        revDict[id] = name
        table.insert(ids_used, id)
        if templateInfo then
            tilesets[name].templateInfo = templateInfo
            templates[templateInfo] = {
                name = name,
                id = id,
                masks = tilesets[name].masks
            }
        end
        if copy then
            local targetName = revDict[copy]
            local target = targetName and tilesets[targetName]
            if not target then
                error(string.format("Copied tilesets must be defined before the tileset coping from them: %s copies %s",
                    id, copy))
            end
            target.used = (target.used and target.used + 1) or 1
            if not target.templateInfo then
                local t_name = string.format("%s(%s)", target.id, targetName)
                if target.id == "z" then
                    t_name = "Vanilla"
                elseif target.id == "9" then
                    t_name = "Wood(Vanilla)"
                end
                templates[t_name] = {
                    name = targetName,
                    id = target.id,
                    masks = target.masks
                }
                target.templateInfo = t_name
            end
        end
    end
    --pick a folder we saw as a place to store tilesets
    local potentials = projectUtils.setAsList(folders)
    if #potentials > 0 then
        handler.tpath = potentials[1]
    end
    --store the tilesets and templates we found in the right place
    if foreground then
        handler.fgTilesets = tilesets
        handler.fgTemplates = templates
    else
        handler.bgTilesets = tilesets
        handler.bgTemplates = templates
    end
    table.sort(ids_used, function(a, b) return a > b end) --sort backwards so the smallest ids are at the end and can be popped quickly
end

local function generateTilesetId()
    local out = utf8.char(curId)
    while out == ids_used[#ids_used] do
        curId += 1
        table.remove(ids_used, #ids_used)
        out = utf8.char(curId)
    end
    curId += 1
    return out
end

---Adds a tileset to the tilesets.xml at target. Can only be called after tilesets are processed
---@param path string the tileset path
---@param displayName string the tileset display name
---@param copy string the template id to copy
---@param sound number the sound number
---@param ignores {[string]:boolean} which tileset ids to ignore
---@param templateInfo string the name for this template(at least one of copy and templateInfo is "")
---@param mask string the mask to apply to this tileset
---@param foreground boolean weather or not this is a forground tileset
---@param xmlTarget string which file to write to
---@return boolean success true when the operation is a success, false otherwise
---@return string? message contains the error message if there was one
---@return string? humMessage contains the message to display to the user in event of error, if there is one
function handler.addTileset(path, displayName, copy, sound, ignores, templateInfo, mask, foreground, xmlTarget)
    local tileXml = (foreground and handler.fgXml) or handler.bgXml
    local id = generateTilesetId()
    local newTileset = {
        _attr = {
            path = path,
            id = id
        }
    }
    local tilesets = (foreground and handler.fgTilesets) or handler.bgTilesets
    local templates = (foreground and handler.fgTemplates) or handler.bgTemplates
    local name = displayName
    if not name then
        name = utils.filename(path, "/") or path
        if not foreground then
            name = string.match(name, "^bg(.*)") or name
        end
        name = utils.humanizeVariableName(name)
    end
    local dict = foreground and handler.revDict.foreground or handler.revDict.background
    tilesets[name] = {
        id = id,
        path = path,
    }
    dict[id] = name
    if #displayName > 0 then
        newTileset._attr.displayName = displayName
    end
    if #copy > 0 then
        newTileset._attr.copy = copy
        tilesets[name].copy = copy
        local ctilset = tilesets[dict[copy]]
        if not ctilset then
            return false, string.format("Tileset %s attempted to copy id %s, but that id does not exist", name, copy),
                "Cannot copy non-existant tileset"
        end
        if not ctilset.templateInfo then
            return false, string.format("Tileset %s attempted to copy a non-template tileseet %s", name, dict[copy]),
                "Cannot copy non-template tileset"
        end
        ctilset.used = (ctilset.used and ctilset.used + 1) or 1
    end
    if sound and sound ~= "0" then
        newTileset._attr.sound = sound
        tilesets[name].sound = sound
    end
    tilesets[name].ignores = ignores
    local ig = projectUtils.listToString(projectUtils.setAsList(ignores))
    if #ig > 0 then newTileset._attr.ignores = ig end
    if #mask > 0 then
        tilesets[name].masks = mask
        local xhandler = xmlHandler:new()
        local parser = xml2lua.parser(xhandler)
        local xml = utils.stripByteOrderMark(mask)
        parser:parse(xml)
        newTileset.set = xhandler.root.set
    end
    if #templateInfo > 0 then
        newTileset._attr.templateInfo = templateInfo
        tilesets[name].templateInfo = templateInfo
        templates[templateInfo] = {
            name = name,
            id = id,
            masks = mask
        }
    end
    local target, msg = io.open(xmlTarget, "w")

    if not target then
        tilesets[name] = nil
        return false, msg, "Cannot add tileset due to filesystem error"
    end
    table.insert(tileXml.Data.Tileset, newTileset)
    local outstring = xmlWriter.toXml(tileXml)
    outstring = fixWierdXml(outstring)

    target:write(outstring)
    target:close()
    return true
end

---Get or create the location of a tileset xml
---@param foreground boolean weather the desired xml is the foregroundTiles.xml or backgroundTiles.xml
---@param projectDetails table the project details(as returned by pUtils.getProjectDetails())
---@return string path the path of the tileset xml
function handler.prepareXmlLocation(foreground, projectDetails)
    local foregroundXml = settings.get("foregroundTilesXml", nil, "recentProjectInfo")
    local backgroundXml = settings.get("backgroundTilesXml", nil, "recentProjectInfo")
    local target = (foreground and foregroundXml) or (not foreground and backgroundXml)
    local targetName = (foreground and "ForegroundTiles.xml") or "BackgroundTiles.xml"
    if not target then
        local ftarget = fileSystem.joinpath(modsDir, projectDetails.name, "Graphics", projectDetails.campaign)
        if not fileSystem.isDirectory(ftarget) then
            fileSystem.mkpath(ftarget)
        end
        return fileSystem.joinpath(ftarget, targetName)
    else
        return fileSystem.joinpath(modsDir, projectDetails.name, target)
    end
end

---Get or create the path at which tileset images should be created
---@param projectDetails table the project details(as returned by pUtils.getProjectDetails())
---@return string tilesetsDir the absolute path to the tileset directory (ie .../Graphics/Atlases/Gameplay/tilesets)
---@return string path the relative path from the tilesetDir to the storage location
function handler.prepareTilesetPath(projectDetails)
    local tilesetsDir = fileSystem.joinpath(modsDir, projectDetails.name, "Graphics", "Atlases", "Gameplay", "tilesets")
    if handler.tpath then return tilesetsDir, handler.tpath end
    local path = projectDetails.campaign
    if not fileSystem.isDirectory(fileSystem.joinpath(tilesetsDir, path)) then
        local success, message = fileSystem.mkpath(fileSystem.joinpath(tilesetsDir, path))
        if not success then
            logging.warning(string.format(
            "Failed to create tilesets folder at %s for project %s due to the following error:\n%s",
                fileSystem.joinpath(tilesetsDir, path), projectDetails.name, message))
            error("Could not make tilesets folder due to filesystem error", 1)
        end
    end
    handler.tpath = path
    return tilesetsDir, path
end

---Move or copy a tileset
---@param copyFile boolean weather to copy or move the item
---@param tilesetFile string the path to the file to move or copy
---@param target string the location the file should be moved or copied to
function handler.mvOrCPtileset(copyFile, tilesetFile, target)
    local success, message
    if copyFile then
        success, message = fileSystem.copy(tilesetFile, target)
    else
        success, message = fileSystem.rename(tilesetFile, target)
    end
    return success, message
end

---Determine weather or not a tileset is vanilla by path
---@param path string the relative path for the tileset from the tileset dir(ie the path attribute for the tileset)
---@return boolean
function handler.isVanilla(path)
    return not (string.find(path, "/"))
end

---Remove a tileset from the xmls
---@param name string the tileset's name
---@param foreground boolean weather or not the tileset is foreground
---@param xmlTarget string the path to the relavant xml file
---@return boolean success
---@return string? error
---@return string? humMessage
function handler.removeTileset(name, foreground, xmlTarget)
    local tileXml = (foreground and handler.fgXml) or handler.bgXml
    local tilesets = foreground and handler.fgTilesets or handler.bgTilesets
    if tilesets[name].used and tilesets[name].used > 0 then
        local msg = string.format("Can't remove %s because it is being used as a template", name)
        return false, msg, "Can't remove tileset being used as a template"
    end
    local target, msg = io.open(xmlTarget, "w")

    if not target then
        return false, msg, "Cannot remove tileset due to fileSystem error"
    end
    local out = tilesets[name]
    local searchId = out.id
    local dict = foreground and handler.revDict.foreground or handler.revDict.background
    if out.copy then
        local ctileset = tilesets[dict[out.copy]]
        ctileset.used = (ctileset.used and ctileset.used > 0 and ctileset.used - 1) or 0
    end
    dict[searchId] = nil
    tilesets[name] = nil
    tileXml.Data.Tileset = $(tileXml.Data.Tileset):filter(tXml -> tXml._attr.id ~= searchId)()
    ids_used = $(ids_used):filter(id-> id~=searchId)
    if searchId < utf8.char(curId) then
        curId -= 1
        local i = utf8.char(curId)
        while i > searchId do
            table.insert(ids_used, i)
            curId -= 1
            --logging.info(string.format("cur id:",curId))
            i = utf8.char(curId)
        end
    end
    local outstring = xmlWriter.toXml(tileXml)
    outstring = fixWierdXml(outstring)
    target:write(outstring)
    target:close()
    return true
end

---Edit a tileset by name
---@param name string the name of the tileset
---@param foreground boolean weather or not the tileset is foregorund
---@param sound integer the new sound for the tileset
---@param ignores {[string]:boolean} the new set of ids this tileset ignores
---@param copyMask string the new id to copy or empty
---@param template string the new name of this template or empty
---@param customMask string the new mask for this tileset
---@param xmlTarget string the path to the xml to edit
---@return boolean success
---@return string? error
---@return string? humMessage
function handler.editTileset(name, foreground, sound, ignores, copyMask, template, customMask, xmlTarget)
    local target, msg = io.open(xmlTarget, "w")
    if not target then
        return false, msg, "Cannot edit tileset due to filesystem error"
    end
    local tilesets = (foreground and handler.fgTilesets) or handler.bgTilesets
    local xml = (foreground and handler.fgXml) or handler.bgXml
    local id = tilesets[name].id
    local idx = $(xml.Data.Tileset):index(t->t._attr.id == id)
    local tileXml = table.remove(xml.Data.Tileset, idx)
    tilesets[name].sound = sound
    tileXml._attr.sound = sound
    tilesets[name].ignores = ignores
    local ig = projectUtils.listToString(projectUtils.setAsList(ignores))
    tileXml._attr.ignores = (#ig > 0 and ig) or nil
    local dict = foreground and handler.revDict.foreground or handler.revDict.background
    local copied = tilesets[name].copy and tilesets[dict[tilesets[name].copy]]
    if copied then
        copied.used = (copied.used and copied.used > 0 and copied.used - 1) or nil
    end
    if #copyMask > 0 then
        tilesets[name].copy = copyMask
        local newCopied = tilesets[dict[copyMask]]
        newCopied.used = (copied.used and copied.used > 0 and copied.used + 1) or 1
    end
    tileXml._attr.copy = (#copyMask > 0 and copyMask) or nil
    tilesets[name].templateInfo = (#template > 0 and template) or nil
    tileXml._attr.templateInfo = (#template > 0 and template) or nil
    if #customMask > 0 then
        tilesets[name].masks = customMask
        local innerxmlHandler = xmlHandler:new()
        local parser = xml2lua.parser(innerxmlHandler)
        local innerxml = utils.stripByteOrderMark(customMask)
        parser:parse(innerxml)
        tileXml.set = innerxmlHandler.root.set
    else
        tilesets[name].masks = nil
        tileXml.set = nil
    end
    if #template > 0 then
        table.insert(xml.Data.Tileset, 1, tileXml)
    else
        table.insert(xml.Data.Tileset, tileXml)
    end
    local outstring = xmlWriter.toXml(xml)
    outstring = fixWierdXml(outstring)
    target:write(outstring)
    target:close()
    return true
end

---sort a list of tilesets in a stable way
---@param tilesets table the tilesets to sort
---@return table sorted
function handler.sortedTilesetOpts(tilesets)
    local opts = {}
    for k, v in pairs(tilesets) do
        table.insert(opts, { k, v.id })
    end
    table.sort(opts, function(a, b)
        return a[1] < b[1]
    end)
    return opts
end

---check if a tileset exists
---@param id string the id to check
---@param foreground boolean weather or not it is foreground
---@return boolean
function handler.isTileset(id, foreground)
    local dict = foreground and handler.revDict.foreground or handler.revDict.background
    if dict[id] then return true end
end

---Update other maps in this campaign to use the correct xmls
---@param projectDetails table the details for the currently loaded project
---@param state table should be require("loaded_state")
---@param foreground boolean weather or not we are doing the foreground tilesets
---@param path string the relative path to the tileset xml
function handler.updateCampaignMetadata(projectDetails, state, foreground, path)
    local clocal = fileSystem.joinpath(modsDir, projectDetails.name, "Maps", projectDetails.username,
        projectDetails.campaign)
    for i, map in ipairs(projectUtils.list_dir(clocal)) do
        local mlocal = fileSystem.joinpath(clocal, map)
        if fileSystem.isFile(mlocal) and state.filename ~= mlocal then
            local s = side_struct.decode(mapcoder.decodeFile(mlocal))
            s.meta = s.meta or {}
            if foreground then
                s.meta.ForegroundTiles = s.meta.ForegroundTiles or path
            else
                s.meta.BackgroundTiles = s.meta.BackgroundTiles or path
            end
            mapcoder.encodeFile(mlocal, side_struct.encode(s))
        end
    end
end
---Check if a tileset is used in the currently loaded map
---@param foreground boolean weather or not it is a foreground tileset
---@param state table the currently loaded state
---@param id string the id of the tileset
---@return boolean present
function handler.checkTileset(foreground, state, id)
    local prop = "tiles"
    if foreground then
        prop = prop .. "Fg"
    else
        prop = prop .. "Bg"
    end
    local idCheck = string.gsub(id, '%W', '%%%1')
    for _, room in ipairs(state.map.rooms) do
        if string.find(tilesStruct.matrixToTileString(room[prop].matrix), idCheck) then
            return true
        end
    end
    return false
end

return handler
