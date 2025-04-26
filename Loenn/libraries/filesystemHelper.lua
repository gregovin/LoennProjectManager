local filesystem = require("utils.filesystem")
local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local fshelp= {}

---Find files in the path folder or any child folder up to "nesting" layers deep
---@param path string
---@param nesting integer
---@param out string[] an outparam which stores the found file paths
local function findRecFilesHelper(path, nesting, out)
    for _,target in pUtils.list_dir(path) do
        local tpath = filesystem.joinpath(path,target)
        if filesystem.isFile(path) then
            table.insert(out, tpath)
        elseif nesting>0 then
            findRecFilesHelper(tpath, nesting-1,out)
        end
    end
end
---Find files in the path folder or any child folder up to "nesting" layers deep
---@param path string
---@param nesting integer
---@return string[] paths the paths to the files that where found
function fshelp.findRecFiles(path,nesting)
    local out = {}
    findRecFilesHelper(path,nesting,out)
    return out
end

---Given a valid folder and file name, returns a file name that is gaurnteed to be (1) valid, (2) contain the fname parameter, and (3) is unique in the target folder
---@param folder string
---@param fname string
---@return string unique_name
function fshelp.getUniqueName(folder, fname)
    local ext = filesystem.fileExtension
    local nname = filesystem.stripExtension(fname)
    while filesystem.pathAttributes(filesystem.joinpath(folder,nname..ext)) do
        nname = nname ..
        string.char(math.random(97, 97 + 25)) --add a random lowercase letter to the filename until its unique
    end
    return nname..ext
end
return fshelp