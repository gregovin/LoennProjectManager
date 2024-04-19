local mods = require("mods")
local warningGenerator = mods.requireFromPlugin("libraries.warningGenerator")
local meta = require("meta")

local script = warningGenerator.makeWarning(
    {("loenn version %s is not supported by this version of loenn project manager"):format(meta.version),
    "Ensure Loenn Project manager and loenn are up to date(and restart loenn).",
    "If that fails, ping @gregovin on the discord"}
)
script.layer="project",
script.displayName = "Version Error"
return script