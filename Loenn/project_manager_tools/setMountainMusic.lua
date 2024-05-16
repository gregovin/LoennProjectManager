
local function musicValidator(s)
    return s=="" or (string.match(s,"^event:/") and not string.match(s,"//"))
end
local script = {
    name="setMountainMusic",
    displayName = "Set Mountain Music",
    layer = "metadata",
    tooltip="Set mountain music and parameters",
    verb = "apply",
    parameters = {
        backgroundMusic= "",
        backgroundAmbience = "",
        backgroundMusicParams= {keys= {""},values={""}},
        backgroundAmbienceParams= {keys= {""},values={""}}
    },
    tooltips = {
        backgroundMusic="The music that plays when you select your map",
        backgroundAmbience="The ambience that plays when you select your map",
        backgroundMusicParams="The music parameters to set when your map is selected",
        backgroundAmbienceParams="The ambience music parameters to set when your map is select"
    },
    fieldInformation={
        backgroundMusic={
            fieldType="string",
            validator = musicValidator
        },
        backgroundAmbience={
            fieldType="string",
            validator = musicValidator
        },
        backgroundMusicParams={
            fieldType="loennProjectManager.dictionary"
        },
        backgroundAmbienceParams={
            fieldType="loennProjectManager.dictionary"
        }
    },
    fieldOrder={"backgroundMusic","backgroundAmbience","backgroundMusicParams","backgroundAmbienceParams"}
}

return script