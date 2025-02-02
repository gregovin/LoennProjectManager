local stringField = require("ui.forms.fields.string")
local logging = require("logging")

-- A field for valid file names on windows(also should work on mac and linux, though is needlessly restrictive)
local fileName = {}

fileName.fieldType = "loennProjectManager.fileName"
---we all love windows so much
local reserved = { "CON", "PRN", "AUX", "NUL", "COM0",
    "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7",
    "COM8", "COM9", "LPT0", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9" }
local whitelist = "[a-zA-Z0-9%-_]+" -- should be fine for all POSIX compliant filesystems and windows
function fileName.getElement(name, value, options)
    -- Add extra options and pass it onto string field
    options.valueTransformer = function(s)
        return s:match("^%s*(.-)%s*$")
    end
    options.validator = function(v)
        if #v == 0 then return true end
        for i, s in ipairs(reserved) do
            if s == string.upper(v) then return false end
        end
        local i, j, _ = string.find(v, whitelist)
        return i == 1 and j == #v and string.sub(v, 1, 1) ~= "-"
    end

    return stringField.getElement(name, value, options)
end

return fileName
