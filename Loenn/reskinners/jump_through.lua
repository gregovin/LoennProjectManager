---@class Reskinner
---@field apply fun(path: string|nil, pdetails: ProjectDetails)? takes the absolute path and project details and performs necesarry transforms. Note if there are multiple the the path points to the base name. Called whenever the reskin changes on allow_many=false options, path is nil for default entry
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
