---------------------------
-- Condition checking whether the player has a minimum number of runes.
-- @class module
-- @name HasRunesCondition

local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local RuneFencer = require('cylibs/entity/jobs/RUN')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasRunesCondition = setmetatable({}, { __index = Condition })
HasRunesCondition.__index = HasRunesCondition
HasRunesCondition.__type = "HasRunesCondition"
HasRunesCondition.__class = "HasRunesCondition"

function HasRunesCondition.new(num_required)
    local self = setmetatable(Condition.new(windower.ffxi.get_player().index), HasRunesCondition)
    self.num_required = num_required or 1
    return self
end

function HasRunesCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        local job = RuneFencer.new()
        local current_runes = job:get_current_runes()
        return current_runes:length() >= self.num_required
    end
    return false
end

function HasRunesCondition:get_config_items()
    return L{
        ConfigItem.new('num_required', 1, 3, 1, nil, "Number Required")
    }
end

function HasRunesCondition:tostring()
    if self.num_required == 1 then
        return "Has >= 1 rune."
    else
        return "Has >= "..self.num_required.." runes."
    end
end

function HasRunesCondition.description()
    return "Has >= X runes."
end

function HasRunesCondition:serialize()
    return "HasRunesCondition.new(" .. serializer_util.serialize_args(self.num_required) .. ")"
end

return HasRunesCondition




