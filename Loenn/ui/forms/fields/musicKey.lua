local stringField = require("ui.forms.fields.string")

-- A field for valid file names on windows(also should work on mac and linux, though is needlessly restrictive)
local musicKey = {}
musicKey.fieldType = "loennProjectManager.musicKey"


function musicKey.getElement(name, value, options)
    -- Add extra options and pass it onto string field
    options.valueTransformer = function(s)
        return s:match("^%s*(.-)%s*$")
    end
    options.validator = function(s)
        return s == "" or (string.match(s, "^event:/") and not string.match(s, "//"))
    end

    return stringField.getElement(name, value, options)
end

return musicKey
