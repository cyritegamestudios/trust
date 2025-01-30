---------------------------
-- Condition checking the target's name.
-- @class module
-- @name TargetNameCondition
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local serializer_util = require('cylibs/util/serializer_util')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local Condition = require('cylibs/conditions/condition')
local TargetNameCondition = setmetatable({}, { __index = Condition })
TargetNameCondition.__index = TargetNameCondition
TargetNameCondition.__class = "TargetNameCondition"
TargetNameCondition.__type = "TargetNameCondition"

function TargetNameCondition.new(name, on_change)
    local self = setmetatable(Condition.new(), TargetNameCondition)
    self.name = name or "Spiny Spipi"
    self.on_change = on_change or true
    return self
end

function TargetNameCondition:is_satisfied(target_index)
    local target
    if target_index == windower.ffxi.get_player().index then
        if windower.ffxi.get_player().target_index then
            target = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
        end
    else
        local enemy = player.party:get_target_by_index(target_index)
        if enemy then
            target = enemy.current_target
        end
    end
    local result = false
    if target and target.name == self.name then
        if self.on_change then
            result = target.name ~= self.last_target_name
        else
            result = true
        end
    end
    self.last_target_name = target and target.name or nil
    return result
end

function TargetNameCondition:get_config_items()
    return L{
        TextInputConfigItem.new('name', self.name, 'Target Name', function(_) return true  end),
        BooleanConfigItem.new('on_change', 'Trigger on Change')
    }
end

function TargetNameCondition:tostring()
    if self.on_change then
        return "Target changed to "..self.name
    else
        return "Targeting "..self.name
    end
end

function TargetNameCondition.description()
    return "Targeting mob with name."
end

function TargetNameCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy }
end

function TargetNameCondition:serialize()
    return "TargetNameCondition.new(" .. serializer_util.serialize_args(self.name, self.on_change) .. ")"
end

return TargetNameCondition




