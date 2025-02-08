local mods = require("mods")
local logging = require("logging")
local uiElements = require("ui.elements")
local languageRegistry = require("language_registry")
local notifications = require("ui.notification")
local projectManager = mods.requireFromPlugin("tools.projectManager")
local repacker = mods.requireFromPlugin("project_manager_tools.repackProject")
local resyncer = mods.requireFromPlugin("project_manager_tools.resyncOpenProject")

local notifHandlers = {}
local eventNotifications = {}
function notifHandlers:loennProjectManagerLooseBinEvent(filename)
    local language = languageRegistry.getLanguage()
    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.loennProjectManager.looseBin)),
            uiElements.row({
                uiElements.button(tostring(language.ui.button.yes), function()
                    projectManager.useScript(repacker, {})
                    popup:close()
                end),
                uiElements.button(tostring(language.ui.button.no), function()
                    popup:close()
                end),
                uiElements.button(tostring(language.ui.button.LoennProjectManager.looseBinSanRemindMeLater), function()
                    if filename then
                        local lpSaveSanitizer = mods.requireFromPlugin("save_sanitizers/loose_project")
                        lpSaveSanitizer.disableEventFor[filename] = true
                    end
                    popup:close()
                end)
            })
        })
    end)
end

function notifHandlers:loennProjectManagerResync(filename)
    local language = languageRegistry.getLanguage()
    notifications.notify(function(popup)
        return uiElements.column({
            uiElements.label(tostring(language.ui.notifications.loennProjectManager.resync)),
            uiElements.row({
                uiElements.button(tostring(language.ui.button.yes), function()
                    resyncer.run()
                    popup:close()
                end),
                uiElements.button(tostring(language.ui.button.no), function()
                    popup:close()
                end),
                uiElements.button(tostring(language.ui.button.LoennProjectManager.looseBinSanRemindMeLater), function()
                    if filename then
                        local lpSaveSanitizer = mods.requireFromPlugin("save_sanitizers/loose_project")
                        lpSaveSanitizer.disableEventFor[filename] = true
                    end
                    popup:close()
                end)
            })
        })
    end)
end

function eventNotifications.getWindow()
    local h = uiElements.group()
    h:with(notifHandlers)
    return h
end

return eventNotifications
