local mods = require("mods")
local metadataHandler = mods.requireFromPlugin("libraries.metadataHandler")
local projectLoader =  mods.requireFromPlugin("libraries.projectLoader")
local pUtils = mods.requireFromPlugin("libraries.projectUtils")

local script = {
    name = "configureOverworldDetails",
    displayName = "Configure Overworld Details",
    tooltip = "Configure overworld effects such as fog and star colors, as well as snow",
    layer = "metadata",
    verb = "apply",
    parameters = {
        showSnow = true,
        fogColors = {"010817","13203E","281A35","010817"},
        starFogColor = "020915",
        starStreamColors = {"000000", "9228e2", "30ffff"},
        starBeltColors1 = {"53f3dd","53c9f3"},
        starBeltColors2 = {"ab6ffa","fa70ea"}
    },
    tooltips = {
        showSnow = "Weather or not to show the snow on the overworld",
        fogColors = "The colors of the fog on the mountain, for each state. 2 colors will be used by the game: the one for the state your custom mountain uses, and the first one (state 0) on the main menu.",
        starFogColor = "The color of the fog in space.",
        starStreamColors = "The color of the 'streams' visible behind the moon",
        starBeltColors1 = "The colors of the small stars rotating around the moon. They are dispatched in 2 \"belts\" that are slightly misaligned between each other.",
        starBeltColors2  = "The colors of the small stars rotating around the moon. They are dispatched in 2 \"belts\" that are slightly misaligned between each other.",
    },
    fieldInformation = {
        showSnow = {fieldType = "boolean"},
        fogColors = {
            fieldType = "loennProjectManager.fixedColorList",
            labels = {"night","dawn","day","moon"}
        },
        starFogColor = {
            fieldType = "color",allowXNAColors=false

        },
        starStreamColors = {
            fieldType = "loennProjectManager.fixedColorList",
            labels = {"Stream 1", "Stream 2", "Stream 3"}
        },
        starBeltColors1 = {
            fieldType = "loennProjectManager.expandableColorList"
        },
        starBeltColors2 = {
            fieldType = "loennProjectManager.expandableColorList"
        }
    },
    fieldOrder = {"fogColors","showSnow","starFogColor","starStreamColors","starBeltColors1","starBeltColors2"}
}

return script