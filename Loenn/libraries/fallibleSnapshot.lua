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
---@return any snapshot
function fallibleSnapshot.create(description, data, backward, forward)
    data = data or {}
    data.success = true
    local wrappedBackward = function(data)
        if data.success then
            --if the last operation was successful, then call backward
            data.success, data.message = pcall(backward, data)
            if not data.success then
                --if we failed log and notify
                logging.warning(data.message)
                notifications.notify(data.message)
            end
            --return if we succeeded
            return data.success
        else
            --Otherwise just do nothing and set success to true so we can retry the previous operation
            data.success = true
        end
    end
    local wrappedforward = function(data)
        if data.success then
            --if the last operation was successful, then call backward
            data.success, data.message = pcall(forward, data)
            if not data.success then
                --if we failed log and notify
                logging.warning(data.message)
                notifications.notify(data.message)
            end
            --return if we succeeded
            return data.success
        else
            --Otherwise just do nothing and set success to true so we can retry the previous operation
            data.success = true
        end
    end
    return snapshot.create(description, data, wrappedBackward, wrappedforward)
end

---Creates one snapshot from a list of snapshots, of which some may be fallible
---@param description string the description of the new snapshot
---@param snapshots table the list of snapshots
---@return any snapshot
function fallibleSnapshot.multiSnapshot(description, snapshots)
    local failed = #snapshots --keep track of which snapshot failed
    local function forward()
        for i = 1, failed do  --loop through all snapshots going forward
            if not snapshots[i].forward(snapshots[i].data) then
                --if one fails lower failed to the one that failed and return
                failed = i
                return false
            end
        end
        --if none fail reset failed and return
        failed = #snapshots
        return true
    end
    local function backward()
        for i = failed, 1, -1 do --loop through snapshots going backwards
            if not snapshots[i].backward(snapshots[i].data) then
                --if one fails lower failed to the one that failed and return
                failed = i
                return false
            end
        end
        --if none fail reset failed and return
        failed = #snapshots
        return true
    end
    return snapshot.create(description, {}, backward, forward)
end

return fallibleSnapshot
