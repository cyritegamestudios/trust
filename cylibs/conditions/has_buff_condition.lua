---------------------------
-- Condition checking whether the player or party member has a buff.
-- @class module
-- @name HasBuffCondition

local buff_util = require('cylibs/util/buff_util')
local party_util = require('cylibs/util/party_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local HasBuffCondition = setmetatable({}, { __index = Condition })
HasBuffCondition.__index = HasBuffCondition
HasBuffCondition.__type = "HasBuffCondition"
HasBuffCondition.__class = "HasBuffCondition"

function HasBuffCondition.new(buff_name, target_index)
    local self = setmetatable(Condition.new(target_index), HasBuffCondition)
    self.buff_name = buff_name
    self.buff_id = buff_util.buff_id(buff_name)
    return self
end

function HasBuffCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        return L(party_util.get_buffs(target.id)):contains(self.buff_id)
    end
    return false
end

function HasBuffCondition:get_config_items()
    local all_buffs = S{
        'Max HP Boost',
        "KO", "weakness", "sleep", "poison",
        "paralysis", "blindness", "silence", "petrification",
        "disease", "curse", "stun", "bind",
        "weight", "slow", "charm", "doom",
        "amnesia", "charm", "gradual petrification", "sleep",
        "curse", "addle",
        "Finishing Move 1", "Finishing Move 2", "Finishing Move 3", "Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)"
    }

    all_buffs:add(self.buff_name)

    all_buffs = L(all_buffs)
    all_buffs:sort()
    return L{
        PickerConfigItem.new('buff_name', self.buff_name, all_buffs)
    }
end

function HasBuffCondition:tostring()
    return "Player is "..res.buffs:with('en', self.buff_name).enl
end

function HasBuffCondition:serialize()
    return "HasBuffCondition.new(" .. serializer_util.serialize_args(self.buff_name) .. ")"
end

return HasBuffCondition




