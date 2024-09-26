local script = {
    name = "addSimpleEndscreen",
    displayName = "Add Simple Endscreen",
    layer = "metadata",
    tooltip = "Add or edit an endscreen with one non-animated image",
    parameters = {
        image  = "",
        start  = { 0.0, 0.0 },
        center = { 0.0, 0.0 },
        offset = { 0.0, 0.0 },
        scale  = 1.0,
        alpha  = 1.0,
        title  = "",
        music  = "",
    },
    tooltips = {
        image = "the image to use for the endscreen",
        start = "the position the image starts with",
        center = "the final position of the image",
        offset = "applies an offset to the image image",
        scale = "the scale of the image",
        alpha = "transparency of the image from 0 to 1",
        speed = "the speed the image move",
        title =
        "Dialog key for the title to use for the endscreen, leave blank for no title. Use \"default\" to get the default key",
        music = "Music event key for the endscreen, if you want to use non-default music"
    },
    fieldInformation = {
        image = {
            fieldType = "loennProjectManager.filePath",
            extension = "png"
        },
        start = {
            fieldType = "loennProjectManager.position2d"
        },
        center = {
            fieldType = "loennProjectManager.position2d"
        },
        offset = {
            fieldType = "loennProjectManager.position2d"
        },
        scale = {
            fieldType = "number",
            minimumValue = 0.0,
        },
        alpha = {
            fieldType = "number",
            minimumValue = 0.0,
            maximumValue = 1.0
        },
        title = {
            fieldType = "string",
            validator = function(s)
                return s == "" or (not string.match(s, "[^a-zA-Z0-9_]"))
            end
        },
        music = {
            fieldType = "loennProjectManager.musicKey"
        }
    },
    fieldOrder = {
        "image", "start", "center", "offset", "music", "title", "alpha"
    }
}
return script
