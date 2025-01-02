local BuffConflictsCondition = require('cylibs/conditions/buff_conflicts')
local BuffTracker = require('cylibs/battle/buff_tracker')

local Buffer = require('cylibs/trust/roles/buffer')
local Warder = setmetatable({}, {__index = Buffer })
Warder.__index = Warder
Warder.__class = "Warder"

function Warder.new(action_queue, buff_settings, state_var)
    local self = setmetatable(Buffer.new(action_queue, buff_settings, state_var), Warder)

    self:set_buff_settings(buff_settings)

    return self
end

function Warder:set_buff_settings(buff_settings)
    Buffer.set_buff_settings(self, buff_settings)

    -- Gambits are handled by Summoner trust
    self:set_gambit_settings(L{})
end

function Warder:get_default_conditions(gambit)
    local conditions = L{
        NotCondition.new(L{ HasBuffCondition.new(gambit:getAbility():get_status().en) }),
        NotCondition.new(L{ BuffConflictsCondition.new(gambit:getAbility():get_status().en)})
    }
    if L(gambit:getAbility():get_valid_targets()) ~= L{ 'Self' } then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end
    return conditions
end

function Warder:allows_duplicates()
    return false
end

function Warder:get_type()
    return "buffer" -- needs to be the same as buffer
end

function Warder:get_cooldown()
    return 3
end

function Warder:get_localized_name()
    return "Buffing"
end

function Warder:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Warder