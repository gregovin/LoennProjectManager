local fileSystem = require("utils.filesystem")
local mods = require("mods")
local logging = require("logging")
local fileLocations = require("file_locations")
local settings = mods.requireFromPlugin("libraries.settings")
local utils = require("utils")
local modsDir = fileSystem.joinpath(fileLocations.getCelesteDir(), "Mods")


local pUtils = {}

function pUtils.passIfFile(path)
    if fileSystem.isFile(path) then return path end
end

---Lists all entries in a dir excluding the backreferences
---@param path string the absolute path to the directory to list
---@return string[] list
function pUtils.list_dir(path)
    local out = {}
    for file in fileSystem.listDir(path) do
        if file ~= "." and file ~= ".." then
            table.insert(out, file)
        end
    end
    return out
end

---Reads a file fron inside this mod as an absolute path
---@param alternate string the relative path from the Loenn folder of this mod to the file
---@return string contents
function pUtils.getInnerXml(alternate)
    return mods.readFromPlugin(alternate)
end

---A helper function to get an xml string from a desired xml or its alternate if not present
---@param location string the relative path to the xml location from the loaded mod root
---@param projectDetails ProjectDetails the details for this project
---@param alternate string the relative path to the alternate xml location form this mod's Loenn folder
---@return string contents the full file contents for the file read
function pUtils.getXmlString(location, projectDetails, alternate)
    if location then
        location = fileSystem.joinpath(modsDir, projectDetails.name, location)
        logging.info(string.format("Reading tilesets.xml at %s", location))
        local out = utils.readAll(location, "rb")
        if out then return out end
        logging.warning("Failed to read tilesets.xml, attempting backup")
    end
    logging.info(string.format("Reading default xml at %s", alternate))
    local out = pUtils.getInnerXml(alternate)
    if out then return out end
    error("Could not read tilesets.xml", 2)
end

---Renders a list to a string for displaying to the user
---@param ls any[] a list (ie ipairs iterable object) containing objects that can be representated as strings
---@param sep string? a string seperator for the printing. Defaults to ","
---@return string
function pUtils.listToString(ls, sep)
    local innerSep = ''
    local res = ''
    if type(ls) ~= 'table' then
        return ls
    end
    for _, v in ipairs(ls) do
        res = res .. innerSep .. (v or "")
        innerSep = sep or ','
    end

    return res
end

---Converts a set(table from objects to booleans) into the list of objects which it contains
---@param set {[any]:boolean} the set to convert
---@return any[] list
function pUtils.setAsList(set)
    local out = {}
    for k, v in pairs(set) do
        if v then
            table.insert(out, k)
        end
    end
    return out
end

---@class ProjectDetails A collection of project details
---@field name string the name of the mod
---@field username string the username associated with the project
---@field campaign string the campaign associated with the project
---@field map string the map associated with the project

---Get the project details for the currently loaded project
---@return ProjectDetails details the project details
function pUtils.getProjectDetails()
    return {
        name = settings.get("name", nil, "recentProjectInfo"),
        username = settings.get("username", nil),
        campaign = settings.get("SelectedCampaign", nil, "recentProjectInfo"),
        map = settings.get("recentmap", nil, "recentProjectInfo")
    }
end

---insert the value into a list, if it isn't null. Otherwise, log toLog
---@param ls any[] the list to insert into
---@param toLog string the thing to log
---@param value any? the value to insert
function pUtils.insertOrLog(ls, toLog, value)
    if value then
        table.insert(ls, value)
    else
        logging.warning(toLog)
    end
end

---if base is a subpath of target returns target minus base
---otherwise returns target
---@param base string
---@param target string
---@return string path the relative path from base to target, or target if base is not a subpath of target
function pUtils.pathDiff(base, target)
    local sbase = fileSystem.splitpath(base)
    local starget = fileSystem.splitpath(target)
    local start, other = string.find(target, base, 1, true)
    if not start or start ~= 1 then
        return target
    end
    local out = starget[#sbase + 1] or ""
    for i = #sbase + 2, #starget, 1 do
        out = fileSystem.joinpath(out, starget[i])
    end
    return out
end

---normalize a string
---@param s string
---@return string
function pUtils.normalize(s)
    return string.lower(string.match(s, "^%s*(.-)%s*$"))
end

--Pngs start with this string of bytes
local pngStartConstant = "\137\80\78\71\13\10\26\10"

---determines if the file at path is a real png
---@param path string
---@return boolean
---@return string? msg relevant error message
---@return string? humMessage notification message
function pUtils.isPng(path)
    local test, message = io.open(path, "rb")
    if not test then
        return false, string.format("Failed to open %s due to a filesystem error:\n%s", path, message),
            "Cannot read tileset file"
    end
    local header = test:read(8)
    assert(test:close())
    return header == pngStartConstant, string.format("%s is a fake png, failed to import", path),
        "Tileset is a fake png. Ask the discord for assistance"
end

return pUtils
