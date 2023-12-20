local stringField = require("ui.forms.fields.string")

local verificationString = {}
verificationString.fieldType = "loennProjectManager.verificationString"

function verificationString.getElement(name, value, options)
    local ctransformer = options.comparisonTransformer or function (s) return s end
    options.validator = function(v)
        return ctransformer(v)==ctransformer(options.requiredValue)
    end

    return stringField.getElement(options.labelName or name, "", options)
end
return verificationString