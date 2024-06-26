---------------------------
-- Job file for Ninja.
-- @class module
-- @name Ninja

local Job = require('cylibs/entity/jobs/job')
local Ninja = setmetatable({}, {__index = Job })
Ninja.__index = Ninja

-------
-- Default initializer for a new Ninja.
-- @treturn NIN A Ninja
function Ninja.new()
    local self = setmetatable(Job.new(), Ninja)

    return self
end

-------
-- Returns whether the player has any copy images.
-- @tparam list player_buff_ids List of active player buffs
-- @treturn boolean True if the player has at least one copy image remaining
function Ninja:has_shadows(player_buff_ids)
    player_buff_ids = L(windower.ffxi.get_player().buffs)
    return buff_util.is_any_buff_active(L{ 66, 444, 445, 446 }, player_buff_ids)
end

return Ninja