local fileLocations = require("file_locations")
local fileSystem = require("utils.filesystem")
local utils = require("utils")
local yaml = require("lib.yaml")
local mods = require("mods")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")
local notifications = require("ui.notification")
local logging = require("logging")
local xml2lua = require("lib.xml2lua.xml2lua")
local modsDir=fileSystem.joinpath(fileLocations.getCelesteDir(),"Mods")

local metadataHandler = {}

metadataHandler.vanillaMountainConfig = {}
metadataHandler.vanillaMountainConfig["Prologue"] = {
    idle = {
        position = {-1.374, 1.224, 7.971},
        target = {-0.440, 0.499, 6.358}
    },
    select = {
        position = {-1.390, 0.784, 7.593},
        target = {-0.052, 0.545, 6.125}
    },
    zoom = {
        position = {-1.104, 0.661, 7.292},
        target = {-0.324, 0.565, 5.452}
    },
    cursor = {-0.880595, 0.8781773, 6.7727},
    state = 0
}
metadataHandler.vanillaMountainConfig["Forsaken City"] = {
    idle = {
        position = {-0.952, 4.218, 9.744},
        target = {-0.111, 3.393, 8.127}
    },
    select = {
        position = {-0.052, 1.659, 9.902},
        target = {1.110, 1.526, 8.280}
    },
    zoom = {
        position = {1.437, 1.896, 7.061},
        target = {1.376, 0.881, 5.338}
    },
    cursor = {1.319535, 2.07172, 5.113717},
    state = 0
}
metadataHandler.vanillaMountainConfig["Old Site"] = {
    idle = {
        position = {-3.399, 5.614, 3.870},
        target = {-2.240, 4.436, 2.743}
    },
    select = {
        position = {-3.890, 3.903, 3.702},
        target = {-2.037, 3.815, 2.955}
    },
    zoom = {
        position = {-3.247, 4.407, 3.251},
        target = {-1.937, 3.720, 1.904}
    },
    cursor = {-2.407315, 4.364232, 2.323102},
    state = 0
}
metadataHandler.vanillaMountainConfig["Celestial Resort"] = {
    idle = {
        position = {5.961, 8.823, 5.058},
        target = {5.061, 7.757, 3.626}
    },
    select = {
        position = {4.294, 6.633, 5.193},
        target = {5.027, 6.828, 3.343}
    },
    zoom = {
        position = {5.200, 6.650, 2.595},
        target = {5.007, 6.391, 0.621}
    },
    cursor = {4.993515, 6.881229, 1.536384},
    state = 1
}
metadataHandler.vanillaMountainConfig["Golden Ridge"] = {
    idle = {
        position = {9.626, 8.824, -4.140},
        target = {7.924, 8.240, -3.267}
    },
    select = {
        position = {8.429, 5.837, -5.086},
        target = {6.662, 6.019, -4.167}
    },
    zoom = {
        position = {7.036, 5.347, -3.231},
        target = {5.522, 5.584, -1.946}
    },
    cursor = {4.481695, 6.766555, -2.226157},
    state = 2
}
metadataHandler.vanillaMountainConfig["Mirror Temple"] = {
    idle = {
        position = {-0.963, 10.542, -5.314},
        target = {-0.178, 9.588, -3.741}
    },
    select = {
        position = {1.786, 8.760, -5.080},
        target = {0.494, 8.810, -3.554}
    },
    zoom = {
        position = {-0.205, 9.318, -4.217},
        target = {-0.729, 9.108, -2.298}
    },
    cursor = {0.2264417, 9.015848, -2.010033},
    state = 2
}
metadataHandler.vanillaMountainConfig["Reflection"] = {
    idle = {
        position = {1.113, 12.154, 6.334},
        target = {-0.086, 11.118, 5.115}
    },
    select = {
        position = {1.113, 12.154, 6.334},
        target = {0.945, 11.175, 4.599}
    },
    zoom = {
        position = {-0.165, 9.961, 2.608},
        target = {-0.726, 8.975, 0.961}
    },
    cursor = {-1.464781, 9.340404, 0.830584},
    state = 0
}
metadataHandler.vanillaMountainConfig["The Summit"] = {
    
    idle = {
        position = {-14.620, 3.606, 19.135},
        target = {-13.134, 4.115, 17.897}
    },
    select = {
        position = {-13.453, 5.141, 18.179},
        target = {-11.907, 5.751, 17.067}
    },
    zoom = {
        position = {-9.156, 6.872, 12.432},
        target = {-8.014, 7.516, 10.922}
    },
    cursor = {-0.2239623, 14.5, -0.6094461},
    state = 1,
    showCore = false
}
metadataHandler.vanillaMountainConfig["Epilogue"] = {
    idle = {
        position = {-1.234, 0.677, 7.598},
        target = {-0.221, 0.734, 5.875}
    },
    select = {
        position = {-1.234, 0.677, 7.598},
        target = {0.010, 0.694, 6.032}
    },
    zoom = {
        position = {-1.104, 0.661, 7.292},
        target = {-0.324, 0.565, 5.452}
    },
    cursor = {-0.880595, 0.8781773, 6.77277},
    state = 0,
    showCore = false
}
metadataHandler.vanillaMountainConfig["Core"] = {
    idle = {
        position = {-4.473, 7.158, 5.463},
        target = {-3.630, 6.660, 3.719}
    },
    select = {
        position = {-3.404, 6.677, 3.846},
        target = {-2.093, 6.202, 2.413}
    },
    zoom = {
        position = {-3.546, 5.962, 0.270},
        target = {-1.596, 5.598, 0.017}
    },
    cursor = {-2.392866, 6.412613, 1.441751},
    state = 2,
    showCore = true
}
metadataHandler.vanillaMountainConfig["Farewell"] = {
    idle = {
        position = {6.4, 33.050, 7.4},
        target = {0, 32.5, 0}
    },
    select = {
        position = {5.881, 31.525, 2.871},
        target = {4.393, 31.481, 1.534}
    },
    zoom = {
        position = {2, 31, 1},
        target = {0, 31, 0}
    },
    cursor = {0, 33.3, 0},
    state = 3,
    rotate = true,
    showCore = false,
    backgroundMusicParams = {
        moon = 1
    }
}

metadataHandler.loadedData = {}
function metadataHandler.clearMetadata()
    metadataHandler.loadedData = {}
end
local function tryReadData(path)
    local content = utils.readAll(path)
    return yaml.read(utils.stripByteOrderMark(content))
end

function metadataHandler.readMetadata(projectDetails)
    --read meta.yaml
    local fLocal = fileSystem.joinpath(modsDir,projectDetails.name,"Maps",projectDetails.username,
    projectDetails.campaign)
    local location = fileSystem.joinpath(fLocal,projectDetails.map..".meta.yaml")
    if fileSystem.isFile(location) then
        logging.info("[Loenn Project Manager] Reading meta.yaml at "..location)
        local success, data = pcall(tryReadData,location)
        if not success then
            logging.warning("[Loenn Project Manager] Failed to read "..location.." due to the following error:\n"..data)
            notifications.notify("Failed to read "..location)
            return
        end
        metadataHandler.loadedFile = location
        metadataHandler.loadedData = data
    else if fileSystem.isDirectory(fLocal) then
        metadataHandler.loadedFile = location
        metadataHandler.loadedData = {}
    end
        metadataHandler.loadedData = {}
    end
end

function metadataHandler.getKey(k)
    return metadataHandler.loadedData and metadataHandler.loadedData[k]
end
function metadataHandler.getNestedValue(keys)
    local v = metadataHandler.loadedData
    for i, key in ipairs(keys) do
        v = v[key]
        if not v then
            return nil
        end
    end
    return v
end
local function recUpdate(tabl, newData)
    for k,v in pairs(newData) do
        if type(v) == "table" then
            if tabl[k] then
                recUpdate(tabl[k],v)
            else
                tabl[k] = v
            end
        else
            tabl[k] = v
        end
    end
end
metadataHandler.defaults = {
    ["Mountain"] = {
        ["ShowSnow"] = true,
        ["FogColors"] = {
            "010817","13203E","281A35","010817"
        },
        ["StarFogColor"]="020915",
        ["StarStreamColors"]={
            "000000",
            "9228e2",
            "30ffff"
        },
        ["StarBeltColors1"] = {
            "53f3dd",
            "53c9f3",
        },
        ["StarBeltColors2"] = {
            "ab6ffa",
            "fa70ea"
        },
        ["BackgroundMusic"] = "",
        ["BackgroundAmbience"] = "",
        ["BackgroundMusicParams"] = {},
        ["BackgroundAmbienceParams"] = {}
    }
}
local function briefList(v)
    return "["..pUtils.listToString(v).."]"
end
metadataHandler.transformers = {
    ["Mountain"] = {
        ["Cursor"] = {transform=briefList},
        ["Idle"] = {
            ["Position"] = {transform=briefList},
            ["Target"] = {transform=briefList}
        },
        ["Select"] = {
            ["Position"] = {transform=briefList},
            ["Target"] = {transform=briefList}
        },
        ["Zoom"] = {
            ["Position"] = {transform=briefList},
            ["Target"] = {transform=briefList}
        }
    }
}
local function sanatizeData(data,transformers)
    local out = {}
    for k,v in pairs(data) do
        if transformers[k] then
            if transformers[k].transform then
                out[k]=transformers[k].transform(v)
            else
                out[k]=sanatizeData(v,transformers[k])
            end
        else
            out[k]=v
        end
    end
    return out
end
--update the metadata to set the keys in newData as they are
function metadataHandler.update(newData)
    recUpdate(metadataHandler.loadedData,newData)
    local sanData = sanatizeData(metadataHandler.loadedData,metadataHandler.transformers)
    local success, reason = yaml.write(metadataHandler.loadedFile,sanData)
    return success, reason
end
local function recSetNested(v,idx,keys,new)
    if idx == #keys then
        v[keys[#keys]] = new
    elseif idx< #keys then
        v[keys[idx]] = v[keys[idx]] or {}
        recSetNested(v[keys[idx]],idx+1,keys,new)
    end
end
function metadataHandler.setNested(v,keys, new)
    recSetNested(v, 1, keys, new)
end

function metadataHandler.getDefault(keys)
    local v = metadataHandler.defaults
    for i, key in ipairs(keys) do
        v = v[key]
        if not v then
            return nil
        end
    end
    return v
end
local function equal(table1, table2)
    if type(table1) ~= type(table2) then return false end
    if type(table1) == "table" then
        local keys = {}
        for k,v in pairs(table1) do
            keys[k] = true
            if not equal(v, table2[k]) then
                return false
            end
        end
        for k,_ in pairs(table2) do
            if not keys[k] then
                return false
            end
        end
        return true
    else
        return table1==table2
    end
end
function metadataHandler.setNestedIfNotDefault(keys,newVal)
    if equal(newVal, metadataHandler.getDefault(keys)) then
        metadataHandler.setNested(metadataHandler.loadedData,keys,nil)
    else
        metadataHandler.setNested(metadataHandler.loadedData,keys, newVal)
    end
end
function metadataHandler.getNestedValueOrDefault(keys)
    return metadataHandler.getNestedValue(keys) or metadataHandler.getDefault(keys)
end
function metadataHandler.write()
    local success, reason = yaml.write(metadataHandler.loadedFile,sanatizeData(metadataHandler.loadedData,metadataHandler.transformers))
    return success, reason
end

return metadataHandler;