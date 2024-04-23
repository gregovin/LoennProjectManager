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
        idlePosition = "",
        idleTarget = "",
        selectPosition = "",
        selectTarget = "",
        zoomPosition = "",
        zoomTarget = "",
        cursor = "",
        state = 0,
        showCore = false,
        rotate = true
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
        local appliedConf = utils.deepcopy(metadataHandler.vanillaMountainConfig[args.copy])
        initScript.nextScript = nil
    else
        initScript.nextScript = detailScript
    end
end
return initScript