-- Borrowed from loenn extended, liscensed under MIT liscense.
local mods = require("mods")
local config = require("utils.config")
local utils = require("utils")
local extSettings = {}

function extSettings.getPersistence(settingName, default)
    local settings = mods.getModPersistence("LoennProjectManager")
    if not settingName then
        return settings
    end

    local value = settings[settingName]
    if value == nil then
        value = default
        settings[settingName] = default
    end

    return value
end

function extSettings.savePersistence()
    config.writeConfig(extSettings.getPersistence(), true)
end

function extSettings.get(settingName, default, namespace)
    local settings = mods.getModSettings("LoennProjectManager")
    if not settingName then
        return settings
    end

    local target = settings
    if namespace then
        local nm = settings[namespace]
        if not nm then
            settings[namespace] = {}
            nm = settings[namespace]
        end

        target = nm
    end

    local value = target[settingName]
    if value == nil then
        value = default
        target[settingName] = default
    end

    if namespace then
        settings[namespace] = utils.deepcopy(target) -- since configMt:__newindex uses ~= behind the scenes to determine whether to save or not, we need to copy the table to make it save
    end

    return value
end

function extSettings.set(settingName, value, namespace)
    local settings = mods.getModSettings("LoennProjectManager")
    local target = settings
    if namespace then
        local nm = settings[namespace]
        if not nm then
            settings[namespace] = {}
            nm = settings[namespace]
        end
        target = nm
    end
    if settingName then
        target[settingName] = value
    end
    if namespace then
        settings[namespace] = utils.deepcopy(target) -- I have no clue if this is needed, I guess so for the same reason as in get
    end
end

return extSettings
