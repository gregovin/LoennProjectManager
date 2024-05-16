local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local logging = require("logging")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local function musicValidator(s)
    return s=="" or (string.match(s,"^event:/") and not string.match(s,"//"))
end
local script = {
    name="setMountainMusic",
    displayName = "Set Mountain Music",
    layer = "metadata",
    tooltip="Set mountain music and parameters",
    verb = "apply",
    parameters = {
        backgroundMusic= "",
        backgroundAmbience = "",
        backgroundMusicParams= {keys= {""},values={""}},
        backgroundAmbienceParams= {keys= {""},values={""}}
    },
    tooltips = {
        backgroundMusic="The music that plays when you select your map",
        backgroundAmbience="The ambience that plays when you select your map",
        backgroundMusicParams="The music parameters to set when your map is selected",
        backgroundAmbienceParams="The ambience music parameters to set when your map is select"
    },
    fieldInformation={
        backgroundMusic={
            fieldType="string",
            validator = musicValidator
        },
        backgroundAmbience={
            fieldType="string",
            validator = musicValidator
        },
        backgroundMusicParams={
            fieldType="loennProjectManager.dictionary"
        },
        backgroundAmbienceParams={
            fieldType="loennProjectManager.dictionary"
        }
    },
    fieldOrder={"backgroundMusic","backgroundAmbience","backgroundMusicParams","backgroundAmbienceParams"}
}
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        script.parameters.backgroundMusic = metadataHandler.getNestedValueOrDefault({"Mountain","BackgroundMusic"})
        script.parameters.backgroundAmbience = metadataHandler.getNestedValueOrDefault({"Mountain","BackgroundAmbience"})
        local musicParams = metadataHandler.getNestedValueOrDefault({"Mountain","BackgroundMusicParams"})
        local parsedMusicParams = {
            keys = {},
            values = {}
        }
        for k,v in pairs(musicParams) do
            table.insert(parsedMusicParams.keys,k)
            table.insert(parsedMusicParams.values,v)
        end
        if #parsedMusicParams.keys ==0 then
            parsedMusicParams.keys = {""}
            parsedMusicParams.values = {""}
        end
        script.parameters.backgroundMusicParams = parsedMusicParams
        local ambienceParams = metadataHandler.getNestedValueOrDefault({"Mountain","BackgroundAmbienceParams"})
        local parsedAmbienceParams = {
            keys ={},
            values = {}
        }
        for k,v in pairs(ambienceParams) do
            table.insert(parsedAmbienceParams.keys,k)
            table.insert(parsedAmbienceParams.values,v)
        end
        script.parameters.backgroundAmbienceParams = parsedAmbienceParams
    elseif not projectDetails.name then
        error("Cannot find tilesets because no project is selected!",2)
    elseif not projectDetails.username then
        error("Cannot find tilesets because no username is selected. This should not happen",2)
    elseif not projectDetails.campaign then
        error("Cannot find tilesets because no campaign is selected!",2)
    else
        error("Cannot find tilesets because no map is selected!",2)
    end
end
function script.run(args)
    local projectDetails = pUtils.getProjectDetails()
    projectLoader.assertStateValid(projectDetails)
    metadataHandler.setNestedIfNotDefault({"Mountain","BackgroundMusic"},args.backgroundMusic)
    metadataHandler.setNestedIfNotDefault({"Mountain","BackgroundAmbience"},args.backgroundAmbience)
    local repackedMusicParams = {}
    for i,k in ipairs(args.backgroundMusicParams.keys) do
        local v = args.backgroundMusicParams.values[i]
        if not(k=="" or v=="") then
            repackedMusicParams[k]=v
        end
    end
    metadataHandler.setNestedIfNotDefault({"Mountain","BackgroundMusicParams"},repackedMusicParams)
    local repackedAmbienceParams = {}
    for i,k in ipairs(args.backgroundAmbienceParams.keys) do
        local v = args.backgroundAmbienceParams.values[i]
        if not (k=="" or v=="") then
            repackedAmbienceParams[k]=v
        end
    end
    metadataHandler.setNestedIfNotDefault({"Mountain","BackgroundAmbienceParams"},repackedAmbienceParams)
    metadataHandler.update({})
end
return script