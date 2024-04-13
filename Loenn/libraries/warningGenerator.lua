local utils = require("utils")
local warningGenerator = {}

local base = {
    name= "GenericWarning",
    displayName="Warning!!!!",
    verb = "continue",
    parameters = {
    },
    tooltips={
        
    },
    fieldInformation ={
    },
    fieldOrder={
    }
}
function warningGenerator.makeWarning(text, tosString, checkText,predicate, callback, next)
    local out = utils.deepcopy(base)
    out.prerun = function ()
        if predicate then
            if not predicate() then
                out.parameters = nil
                out.run = function(args) end
                return
            end
        end
        text = utils.callIfFunction(text)
        if type(text)=="string" then
            out.parameters.warning = ""
            out.fieldInformation.warning={
                fieldType="loennProjectManager.label",
                labelName=text
            }
            table.insert(out.fieldOrder,"warning")
        elseif type(text)=="table" then
            if #text>0 then
                for i,v in ipairs(text) do
                    local pname="warning"..i
                    out.parameters[pname]=""
                    out.fieldInformation[pname]={
                        fieldType="loennProjectManager.label",
                        labelName=v
                    }
                    table.insert(out.fieldOrder,pname)
                end
                else
                    for k,v in pairs(text) do
                        local pname=string.format("warning%s",k)
                        out.parameters[pname]=""
                        out.fieldInformation[pname]={
                            fieldType="loennProjectManager.label",
                            labelName=v
                        }
                        table.insert(out.fieldOrder,pname)
                    end
                end
        else
            error("text had invalid type",2)
        end
        tosString=utils.callIfFunction(tosString)
        if tosString then
            local name = "Enter " .. tosString .. " to proceed"
            out.parameters[name] = ""
            out.tooltips[name] = "Enter the sting \""..tosString.. "\" to certify that you have read and understood this warning and wish to proceed"
            out.fieldInformation[name]={
                fieldType = "loennProjectManager.verificationString",
                requiredValue = tosString,
                displayName = name
            }
            table.insert(out.fieldOrder, name)
        end
        checkText=utils.callIfFunction(checkText)
        if checkText then
            out.parameters.checkText = false
            out.tooltips.checkText = "Check this box to certify that you have read and understood this warning and wish to proceed"
            out.fieldInformation.checkText = {
                fieldType = "loennProjectManager.verificationCheckbox",
                labelName = checkText
            }
            table.insert(out.fieldOrder,"checkText")
        end
    end
    function out.run(args)
        utils.callIfFunction(callback) --args contain no useful info
    end
    out.nextScript = next
    return out
end
return warningGenerator