local stringField = require("ui.forms.fields.string")

-- A field for valid xml attributes
local fileName = {}
 
fileName.fieldType = "loennProjectManager.xmlAttribute"
local pattern = "^[^<>'\"&%c]*$"
---validate that v is a valid xml attribute
---@param v string
local function validator(v)
    return v:match(pattern)
end

function fileName.getElement(name, value, options)
    -- Add extra options and pass it onto string field
    options.valueTransformer = function(s)
        return string.gsub(s,"%s+"," ")
    end
    options.validator = validator

    return stringField.getElement(name, value, options)
end

return fileName