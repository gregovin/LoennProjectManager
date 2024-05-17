local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local projectLoader = mods.requireFromPlugin("libraries.projectLoader")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local logging = require("logging")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")


local script = {
    name = "setMountainTextures",
    displayName = "Set Mountain Textures",
    layer="metadata",
    verb = "apply",
    tooltip = "Modify the overworld textures",
    parameters = {
        textures = {""},
        models = {""},
    },
    tooltips = {
        textures = "Mountain texture files to use. To reset remove all items. Always coppies selected files and deletes present files.",
        models = "Mountain modes to use. To reset remove all items. Always coppies selected files and deletes present files."
    },
    fieldInformation = {
        textures = {
            fieldType = "loennProjectManager.filePathList",
            extension = "png",
            allowEmpty = true
        },
        models = {
            fieldType = "loennProjectManager.filePathList",
            extension = "obj",
            allowEmpty = true
        }
    },
    fieldOrder = {"textures","models"}
}
local function getMontainLocales(projectDetails)
    local textureLocale = metadataHandler.getNestedValue({"Mountain","MountainTextureDirectory"})
    local mountainModelLocale = metadataHandler.getNestedValue({"Mountain","MountainModelDirectory"})
    if textureLocale then
        textureLocale = fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Mountain",textureLocale)
    else
        textureLocale = fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Mountain",projectDetails.username,projectDetails.campaign)
    end
    if mountainModelLocale then
        mountainModelLocale = fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases",mountainModelLocale)
    else
        mountainModelLocale = fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Mountain",projectDetails.username,projectDetails.campaign)
    end
    script.textureLocale = textureLocale
    script.mountainModelLocale = mountainModelLocale
end
function script.prerun()
    local projectDetails = pUtils.getProjectDetails()
    if projectDetails.name and projectDetails.username and projectDetails.campaign and projectDetails.map then
        projectLoader.assertStateValid(projectDetails)
        if not projectLoader.cacheValid then
            projectLoader.loadMetadataDetails(projectDetails)
        end
        getMontainLocales(projectDetails)
        local textures = {}
        if fileSystem.isDirectory(script.textureLocale) then
            for v in fileSystem.listDir(script.textureLocale) do
                local target = fileSystem.joinpath(script.textureLocale,v)
                if fileSystem.isFile(target) and fileSystem.fileExtension(target)=="png" then
                    table.insert(textures, target)
                end
            end
        else
            table.insert(textures,"")
        end
        local models = {}
        if fileSystem.isDirectory(script.mountainModelLocale) then
            for v in fileSystem.listDir(script.mountainModelLocale) do
                local target  = fileSystem.joinpath(script.mountainModelLocale,v)
                if fileSystem.isFile(target) and fileSystem.fileExtension(target)=="obj" then
                    table.insert(models, target)
                end
            end
        else
            table.insert(models,"")
        end
        script.parameters.models = models
        script.parameters.textures = textures
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
    local textures = {}
    for _,v in ipairs(args.textures) do
        if fileSystem.isFile(v) and fileSystem.fileExtension(v)=="png" then
            table.insert(textures, v)
        end
    end
    local models = {}
    for _,v in ipairs(args.models) do
        if fileSystem.isFile(v) and fileSystem.fileExtension(v)=="obj" then
            table.insert(models,v)
        end
    end
    if fileSystem.isDirectory(script.textureLocale) then
        for v in fileSystem.listDir(script.textureLocale) do
            local target = fileSystem.joinpath(script.textureLocale,v)
            if fileSystem.isFile(target) and fileSystem.fileExtension(target) == "png" then
                local keep = false
                for _,f in ipairs(textures) do
                    if f==target then
                        keep =true
                    end
                end
                if not keep then
                    fileSystem.remove(target)
                end
            end
        end
    end
    if #textures>0 then
        if not fileSystem.isDirectory(script.textureLocale) then
            fileSystem.mkpath(script.textureLocale)
        end
        local path = pUtils.pathDiff(fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases","Mountain"),script.textureLocale)
        metadataHandler.setNested(metadataHandler.loadedData,{"Mountain","MountainTextureDirectory"},string.gsub(path,"\\","/"))
        for _,v in ipairs(textures) do
            local target = fileSystem.joinpath(script.textureLocale,fileSystem.filename(v))
            fileSystem.copy(v,target)
        end
    else
        metadataHandler.setNested(metadataHandler.loadedData,{"Mountain","MountainTextureDirectory"},nil)
    end
    if fileSystem.isDirectory(script.mountainModelLocale) then
        for v in fileSystem.listDir(script.mountainModelLocale) do
            local target = fileSystem.joinpath(script.mountainModelLocale,v)
            if fileSystem.isFile(target) and fileSystem.fileExtension(target) == "obj" then
                local keep = false
                for _,v in ipairs(models) do
                    if v==target then
                        keep =true
                    end
                end
                if not keep then
                    fileSystem.remove(target)
                end
            end
        end
    end
    if #models>0 then
        if not fileSystem.isDirectory(script.mountainModelLocale) then
            fileSystem.mkpath(script.mountainModelLocale)
        end
        local path = pUtils.pathDiff(fileSystem.joinpath(modsDir,projectDetails.name,"Graphics","Atlases"),script.mountainModelLocale)
        metadataHandler.setNested(metadataHandler.loadedData,{"Mountain","MountainModelDirectory"},string.gsub(path,"\\","/"))
        for _,v in models do
            local target = fileSystem.joinpath(script.mountainModelLocale,fileSystem.filename(v))
            fileSystem.copy(v,target)
        end
    else
        metadataHandler.setNested(metadataHandler.loadedData,{"Mountain","MountainModelDirectory"},nil)
    end
    local success, reason = metadataHandler.update({})
end
return script