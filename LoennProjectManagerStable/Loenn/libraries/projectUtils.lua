local fileSystem = require("utils.filesystem")
local mods = require("mods")
local logging = require("logging")
local fileLocations = require("file_locations")
local utils = require("utils")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local pUtils = {}
function pUtils.list_dir(path)
    local out = {}
    for file in fileSystem.listDir(path) do
        if file ~= "." and file ~= ".." then
            table.insert(out,file)
        end
    end
    return out
end
function pUtils.getXmlString(location, projectDetails,alternate)
    if location then
        location = fileSystem.joinpath(modsDir,projectDetails.name,location)
        logging.info(string.format("attempting to read tilesets.xml at %s",location))
        local out = utils.readAll(location, "rb")
        if out then return out end
        logging.warning("Failed to read tilesets.xml, attempting backup")
    end
    local info,metadata=mods.findLoadedMod(mods.getCurrentModName())
    local ownpath= metadata._path
    local xmlpath=fileSystem.joinpath(ownpath,alternate)
    logging.info(string.format("Attempting to read provided tilesets.xml at %s",xmlpath))
    local out = utils.readAll(xmlpath,"rb")
    if out then return out end
    error("Could not read tilesets.xml",2)
end
return pUtils