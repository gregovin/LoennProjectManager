---@class Reskinner
---@field apply fun(path: string, pdetails: ProjectDetails)?
local reskinner = {
    name = "Jump Through",
    allow_many = true,
    multifile = false,
    target_dir = "objects/jumpthru",
    effects_entity = "jumpThru",
    affected_field = "texture",
    append_mod_info=true
}


return reskinner
