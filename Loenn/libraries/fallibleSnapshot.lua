local utils = require("utils")
local snapshot = require("structs.snapshot")
local logging = require("logging")
local notifications = require("ui.notification")

local fallibleSnapshot={}

function fallibleSnapshot.create(description,data,backward,forward)
    data=data or {}
    data.success = true
    local wrappedBackward = function(data)
        if data.success then
            data.success,data.message=pcall(backward,data)
            if not data.success then
                logging.info(data.message)
                notifications.notify(data.message)
            end
            return data.success
        else
            data.success=true
        end
    end
    local wrappedforward = function(data)
        if data.success then
            data.success,data.message=pcall(forward,data)
            if not data.success then  notifications.notify(data.message) end
            return data.success
        else
            data.success=true
        end
    end
    return snapshot.create(description,data,wrappedBackward,wrappedforward)
end
---Creates one snapshot from a list of snapshots, of which some may be fallible
---@param description string the description of the new snapshot
---@param snapshots table the list of snapshots
---@return any snapshot the fallible snapshot
function fallibleSnapshot.multiSnapshot(description,snapshots)
    local failed=#snapshots
    local function forward()
        for i=1,failed do
            if not snapshots[i].forward(snapshots[i].data) then
                failed=i
                return true
            end
        end
        failed=#snapshots
    end
    local function backward()
        for i=failed,1,-1 do
            if not snapshots[i].backward(snapshots[i].data) then
                failed=i
                return true
            end
        end
        failed=#snapshots
    end
    return snapshot.create(description,{},backward,forward)
end
return fallibleSnapshot