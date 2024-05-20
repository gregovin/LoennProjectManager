local utils = require("utils")
local snapshot = require("structs.snapshot")
local logging = require("logging")
local notifications = require("ui.notification")

local fallibleSnapshot = {}
---Creates a snapshot that can fail sainly
---@param description string the description as used by history
---@param data table the initial data. Note that {success=true} can set weather the previous call was successful
---@param backward function The callback to run when undo is pressed
---@param forward function The callback to run when redo is pressed
---@return any snapshot the resulting snapshot, with failure sainly accounted for, ready to add to the history
function fallibleSnapshot.create(description, data, backward, forward)
    data = data or {}
    data.success = true
    local wrappedBackward = function(data)
        if data.success then
            data.success, data.message = pcall(backward, data)
            if not data.success then
                logging.warning(data.message)
                notifications.notify(data.message)
            end
            return data.success
        else
            data.success = true
        end
    end
    local wrappedforward = function(data)
        if data.success then
            data.success, data.message = pcall(forward, data)
            if not data.success then notifications.notify(data.message) end
            return data.success
        else
            data.success = true
        end
    end
    return snapshot.create(description, data, wrappedBackward, wrappedforward)
end

---Creates one snapshot from a list of snapshots, of which some may be fallible
---@param description string the description of the new snapshot
---@param snapshots table the list of snapshots
---@return any snapshot the fallible snapshot
function fallibleSnapshot.multiSnapshot(description, snapshots)
    local failed = #snapshots
    local function forward()
        for i = 1, failed do
            if not snapshots[i].forward(snapshots[i].data) then
                failed = i
                return true
            end
        end
        failed = #snapshots
    end
    local function backward()
        for i = failed, 1, -1 do
            if not snapshots[i].backward(snapshots[i].data) then
                failed = i
                return true
            end
        end
        failed = #snapshots
    end
    return snapshot.create(description, {}, backward, forward)
end

return fallibleSnapshot
