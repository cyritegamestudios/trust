---------------------------
-- Condition checking whether the player has the given buffs.
-- @class module
-- @name HasBuffsCondition

local Condition = require('cylibs/conditions/condition')
local HasBuffsCondition = setmetatable({}, { __index = Condition })
HasBuffsCondition.__index = HasBuffsCondition

function HasBuffsCondition.new(buff_names, require_all)
    local self = setmetatable(Condition.new(), HasBuffsCondition)
    self.buff_ids = buff_names:map(function(buff_name) return buff_util.buff_id(buff_name)  end)
    self.require_all = require_all
    return self
end

function HasBuffsCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target and target.index == windower.ffxi.get_player().index then
        local player_buff_ids = L(windower.ffxi.get_player().buffs)
        for buff_id in self.buff_ids:it() do
            local is_buff_active = buff_util.is_buff_active(buff_id, player_buff_ids)
            if self.require_all then
                if not is_buff_active then
                    return false
                end
            else
                if is_buff_active then
                    return true
                end
            end
        end
    end
    if self.require_all then
        return true
    else
        return false
    end
end

function HasBuffsCondition:is_player_only()
    return true
end

return HasBuffsCondition




