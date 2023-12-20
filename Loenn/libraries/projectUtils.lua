local fileSystem = require("utils.filesystem")
local mods = require("mods")
local logging = require("logging")
local fileLocations = require("file_locations")
local settings = mods.requireFromPlugin("libraries.settings")
local utils = require("utils")
local lfs = require("lib.lfs_ffi")
local ffi = require "ffi"
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")
local osUtils = require("utils.os")


local pUtils = {}
---A helper function which lists all entries in a dir excluding the backreferences
---@param path string the absolute path to the directory to list
---@return string[] list the list of filenames in that directory
function pUtils.list_dir(path)
    local out = {}
    for file in fileSystem.listDir(path) do
        if file ~= "." and file ~= ".." then
            table.insert(out,file)
        end
    end
    return out
end
---A helper function which gets an location inside this mod as an absolute path
---@param alternate string the relative path from the root of this mod to the file
---@return string path the absolute path to the desired item
function pUtils.getInnerXmlLocation(alternate)
    local info,metadata=mods.findLoadedMod(mods.getCurrentModName())
    return fileSystem.joinpath(metadata._path,alternate)
end
---A helper function to get an xml string from a desired xml or its alternate if not present
---@param location string the relative path to the xml location from the mod root
---@param projectDetails table the details for this project(as returned by pUtils.getProjectDetails())
---@param alternate string the relative path to the alternate xml location form this mods root
---@return string contents the full file contents for the file read
function pUtils.getXmlString(location, projectDetails,alternate)
    if location then
        location = fileSystem.joinpath(modsDir,projectDetails.name,location)
        logging.info(string.format("Reading tilesets.xml at %s",location))
        local out = utils.readAll(location, "rb")
        if out then return out end
        logging.warning("Failed to read tilesets.xml, attempting backup")
    end
    local xmlpath=pUtils.getInnerXmlLocation(alternate)
    logging.info(string.format("Reading tilesets.xml at %s",xmlpath))
    local out = utils.readAll(xmlpath,"rb")
    if out then return out end
    error("Could not read tilesets.xml",2)
end
---Renders a list to a string for displaying to the user
---@param ls any[] a list (ie ipairs iterable object) containing objects that can be representated as strings
---@return string out the string to show to the end user
function pUtils.listToString(ls)
    local sep = ''
    local res = ''
    if type(ls) ~= 'table' then
        return ls
    end

    for k,v in ipairs(ls) do
        res = res .. sep .. v
        sep = ','
    end

    return res
end
---Converts a set(table from objects to booleans) into the list of objects which it contains
---@param set {[any]:boolean} the set to convert 
---@return any[] list the objects the set contains
function pUtils.setAsList(set)
    local out = {}
    for k,v in pairs(set) do
        if v then
            table.insert(out,k)
        end
    end
    return out
end
---Get the project details for the currently loaded project
---@return {name:string,username:string,campaign:string,map:string} details the project details
function pUtils.getProjectDetails()
    return {
        name=settings.get("name",nil,"recentProjectInfo"),
        username=settings.get("username",nil),
        campaign=settings.get("SelectedCampaign",nil,"recentProjectInfo"),
        map=settings.get("recentmap",nil,"recentProjectInfo")
    }
end
---insert the value into a list, if it isn't null. Otherwise, log toLog
---@param ls any[] the list to insert into
---@param toLog string the thing to log
---@param value any? the value to insert
function pUtils.insertOrLog(ls, toLog, value)
    if value then
        table.insert(ls,value)
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
    local sbase= fileSystem.splitpath(base)
    local starget = fileSystem.splitpath(target)
    local start, other = string.find(target,base,1,true)
    if not start or start ~=1 then
        return target
    end
    local out= starget[#sbase+1] or ""
    for i=#sbase+2,#starget,1 do
        out = fileSystem.joinpath(out,starget[i])
    end
    return out
end
---normalize a string
---@param s string
---@return string
function pUtils.normalize(s)
    return string.lower(string.match(s,"^%s*(.-)%s*$"))
end
return pUtils