local fileSystem = require("utils.filesystem")
local fileLocations = require("file_locations")
local logging = require("logging")
local lfs = require("lib.lfs_ffi")
local settings = require("mods").requireFromPlugin("libraries.settings")

local timestampFormat = "%Y-%m-%d %H-%M-%S"
local timestampPattern = ".*(%d%d%d%d)-(%d%d)-(%d%d) (%d%d)-(%d%d)-(%d%d)"
local safeDelete = {}
--get the storage folder
safeDelete.folder = fileSystem.joinpath(fileLocations.getStorageDir(), "LPMTrash")
---get the names of the deleted items
---@return string[] names
function safeDelete.getImageNames()
    local filenames = {}
    for filename in lfs.dir(safeDelete.folder) do
        if string.match(filename, timestampPattern) then
            local fullPath = fileSystem.joinpath(safeDelete.folder, filename)
            table.insert(filenames, fullPath)
        end
    end
    return filenames
end

local function getTimeFromFilename(filename)
    local year, month, day, hour, minute, second = string.match(filename, timestampPattern)

    return os.time({ year = year, month = month, day = day, hour = hour, min = minute, sec = second })
end
--This function should run on tool load(ie startup)
--It cleans up old backups
function safeDelete.startup()
    --if the directory doesn't exist, make it
    if not fileSystem.isDirectory(safeDelete.folder) then
        fileSystem.mkpath(safeDelete.folder)
    end
    --determine how many files there are and what their names are
    local imageFilenames = safeDelete.getImageNames()
    local filecount = #imageFilenames
    --get the maximum number of backups allowed
    local maximumBackups = settings.get("DesiredLargeBackups", 20)
    if filecount > maximumBackups then
        --if we need to prune files, log that we are doing so
        logging.info("[Loenn Project Manager] pruning backup files")
        --compile a list of filenames and times, and sort by time
        local fileInformations = {}
        for i, filename in ipairs(imageFilenames) do
            fileInformations[i] = {
                filename = filename,
                created = getTimeFromFilename(filename)
            }
        end
        table.sort(fileInformations, function(a, b)
            return a.created > b.created
        end)
        while filecount > maximumBackups do
            --get the oldest file, and delete it
            local delName = fileInformations[filecount].filename
            if not delName then
                break
            end
            local success = os.remove(delName)
            if not success then break end
            table.remove(fileInformations, filecount)
            filecount -= 1
        end
    end
end

---reversibly delete a file by temporarily moving it to safeDelete.folder and eventually deleting it
---@param path string the path of the file to delete
---@return boolean|string newname if successful, this will be the files new location. Otherwise false
---@return string? error contains the error message, if there was one
function safeDelete.revdelete(path)
    local timestamp = os.date(timestampFormat, os.time())
    local prevFilename = fileSystem.filename(path)
    local name = string.gsub(fileSystem.stripExtension(prevFilename), timestampPattern, "timestamp") --make sure timestamp is uniquely identifiable
    local ext = fileSystem.fileExtension(prevFilename)
    local newname = fileSystem.joinpath(safeDelete.folder, name .. timestamp .. "." .. ext)
    local success, message = os.rename(path, newname)
    return success and newname, message
end

return safeDelete
