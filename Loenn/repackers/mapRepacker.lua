local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local tempfolder = fileSystem.joinpath(fileLocations.getStorageDir(), "LPMTemp")

local packer = {
    entry = "maps",
    overides = true,
}
---Apply this repacker
---@param modname string the name of the mod
---@param umap {[string]: string} a single element table with umap[currentUsername]=newUsername
---@param content_map {[string|integer]: CMAP} a map from old campaigns to new campaigns. 0 is a sentinel key for unstructured items
---@param topdir string the path to the top level mod dir
function packer.apply(modname, umap, content_map, topdir)
    if not fileSystem.isDirectory(tempfolder) then
        fileSystem.mkpath(tempfolder)
    end
    ---select the map directory
    local mapdir = fileSystem.joinpath(topdir, "Maps")
    --extract the usernames from the umap
    local oldusername
    local newusername
    for k, v in pairs(umap) do
        oldusername = k
        newusername = v
    end
    --if the map directory isn't real, look around for any bins
    if not fileSystem.isDirectory(mapdir) then
        local targets = pUtils.list_dir(topdir)
        fileSystem.mkpath(mapdir)
        for _, f in targets do
            if fileSystem.extension(f) == "bin" then
                fileSystem.rename(fileSystem.joinpath(topdir, f), fileSystem.joinpath(mapdir, f))
            end
        end
    end
    --locally story variables for the user dirs
    local newuserdir = fileSystem.joinpath(mapdir, newusername)
    local olduserdir = #oldusername > 0 and fileSystem.joinpath(mapdir, oldusername)
    if fileSystem.isDirectory(olduserdir) then
        --if the old username is a valid directory, just rename it
        fileSystem.rename(olduserdir, newuserdir)
    elseif not fileSystem.isDirectory(newuserdir) then
        --otherwise make the new directory and move everything into it
        local targets = pUtils.list_dir(mapdir)
        fileSystem.mkpath(newuserdir)
        for _, v in targets do
            fileSystem.rename(fileSystem.joinpath(mapdir, v), fileSystem.joinpath(newuserdir, v))
        end
    end
    --iterate through each item in the user directory. We expect these to be campaigns
    for _, cname in ipairs(pUtils.list_dir(newuserdir)) do
        --keep track of the old file
        local olditem = fileSystem.joinpath(newuserdir, cname)
        if fileSystem.isDirectory(olditem) then                                                          --if its a folder we have a campaign
            if content_map[cname] then
                local newcamp = fileSystem.joinpath(tempfolder, "campaigns", content_map[cname].newName) --so keep track of the new path
                fileSystem.rename(olditem, newcamp)                                                      --and rename it
                --note we put this in the temp folder so we can swap two campaigns names are fine
                --then iterate over each file in the dir
                for _, mapf in ipairs(pUtils.list_dir(newcamp)) do
                    local mapname = fileSystem.stripExtension(mapf)
                    --if its a file we have a remaping for
                    local oldmap = fileSystem.joinpath(newcamp, mapf)
                    if fileSystem.isFile(oldmap) and content_map[cname].mapMap[mapname] then
                        --do the remapping
                        --Put the new file in the temp folder to allow file swapping
                        fileSystem.rename(oldmap,
                            fileSystem.joinpath(tempfolder, "maps", content_map[cname].mapMap[mapname] .. ".bin"))
                        --if we have a meta.yaml file for it also map that
                        local oldyml = fileSystem.joinpath(newcamp, mapname .. ".meta.yaml")
                        if fileSystem.isFile(oldyml) then
                            fileSystem.rename(oldyml,
                                fileSystem.joinpath(tempfolder, "maps",
                                    content_map[cname].mapMap[mapname] .. ".meta.yaml"))
                        end
                    end
                end
                fileSystem.rename(fileSystem.joinpath(tempfolder, "maps"), newcamp)
            end
        elseif content_map[0] then --if the item is a file, then it belongs to a degenerate campaign which has sentinel key 0
            local mapname = fileSystem.stripExtension(cname)
            --if we have a remapping for this file, do it
            if content_map[0].mapMap[mapname] then
                local newcamp = fileSystem.joinpath(tempfolder, "campaigns", content_map[0].newName)
                fileSystem.mkpath(newcamp)
                fileSystem.rename(olditem, fileSystem.joinpath(newcamp, content_map[0].mapMap[mapname] .. ".bin"))
                local oldyml = fileSystem.joinpath(newcamp, mapname .. ".meta.yaml")
                if fileSystem.isFile(oldyml) then
                    fileSystem.rename(oldyml,
                        fileSystem.joinpath(newcamp, content_map[cname].mapMap[mapname] .. ".meta.yaml"))
                end
            end
        end
    end
    fileSystem.rename(fileSystem.joinpath(tempfolder, "campaigns"), newuserdir) --move the campaigns back into the mod
end

return packer
