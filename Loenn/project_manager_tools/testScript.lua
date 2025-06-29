local mods = require("mods")

local tilesetHandler = mods.requireFromPlugin("libraries.tilesetHandler")
local script ={
    name="Test",
    displayName = "Test",
    tooltip = "Test tileset generation",
    layer = "foreground",
    verb = "test",
}

function script.run(args)
    tilesetHandler.id_test()
end
return script