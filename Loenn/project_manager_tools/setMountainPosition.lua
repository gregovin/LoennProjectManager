local logging = require("logging")
local mods = require("mods")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local utils = require("utils")

local detailScript = {
    name = "setMountainPos",
    displayName = "Set Mountain Positon",
    layer="metadata",
    verb = "apply",
    tooltip = "Modify where your map appears in the overworld, as well as the overworld state when your map is selected.\nSee the Overworld Customisation page on the everest api wiki for more info on how to use this",
    parameters = {
        idlePosition = {0,0,0},
        idleTarget = {0,0,0},
        selectPosition = {0,0,0},
        selectTarget = {0,0,0},
        zoomPosition = {0,0,0},
        zoomTarget = {0,0,0},
        cursor = {0,0,0},
        state = 0,
        showCore = false,
        rotate = false
    },
    tooltips = {
        idlePosition = "The position of the camera durring level selection on the overworld.",
        idleTarget = "The position the camera is looking at durring level selection",
        selectPosition = "The position of the camera when this map is selected.",
        selectTarget = "The target of the camera when this map is selected",
        zoomPosition = "The position of the camera when zooming into the map when pressing start",
        zoomTarget = "The position of the camera target when zooming into the map when pressing start",
        cursor = "The location of the madeline cursor on the mountain",
        state = "The lighting of the mountain",
        showCore = "Whether or not the core heart is shown on the mountain",
        rotate = "Wether or not the camera should rotate oround the mountian"
    },
    fieldInformation = {
        idlePosition = {fieldType = "loennProjectManager.position3d"},
        idleTarget = {fieldType = "loennProjectManager.position3d"},
        selectPosition= {fieldType = "loennProjectManager.position3d"},
        selectTarget = {fieldType = "loennProjectManager.position3d"},
        zoomPosition = {fieldType = "loennProjectManager.position3d"},
        zoomTarget = {fieldType = "loennProjectManager.position3d"},
        cursor = {fieldType = "loennProjectManager.position3d"},
        state = {
            fieldType = "integer",
            options ={{"night",0},{"dawn",1},{"day",2},{"moon",3}}
        },
        showCore = {fieldType = "boolean"},
        rotate = {fieldType = "boolean"}
    },
    fieldOrder={
        "idlePosition","idleTarget","selectPosition","selectTarget","zoomPosition","zoomTarget","cursor","state","showCore","rotate"
    }
}
local initScript = {
    name = "setMountainPos",
    displayName = "Set Mountain Position",
    layer="metadata",
    tooltip = "Modify where your map appears in the overworld, as well as the overworld state when your map is selected.\nSee the Overworld Customisation page on the everest api wiki for more info on how to use this",
    parameters = {
        copy = "",
        overideOtherConfig=true,
    },
    tooltips = {
        copy = "The map whose details to copy. Leave unset to specify the details manually",
    },
    fieldInformation = {
        copy = {
            fieldType = "string",
            options = {"Prologue","Forsaken City","Old Site","Celestial Resort","Golden Ridge","Mirror Temple","Reflection","The Summit","Epilogue","Core","Farewell"}
        },
    },
    fieldOrder = {"copy","overideOtherConfig"}
}
function initScript.run(args)
    if args.copy ~="" then
        local appliedConf = metadataHandler.vanillaMountainConfig[args.copy]
        initScript.nextScript = nil
    else
        initScript.nextScript = detailScript
    end
end
function detailScript.run(args)
    logging.info(string.format("x: %s,y: %s, z: %s",args.idlePosition[1],args.idlePosition[2],args.idlePosition[3]))
end
return initScript