---------------------------
-- Condition checking whether the player, party member or enemy gains a debuff.
-- @class module
-- @name GainDebuffCondition

local buff_util = require('cylibs/util/buff_util')
local serializer_util = require('cylibs/util/serializer_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local Condition = require('cylibs/conditions/condition')
local GainDebuffCondition = setmetatable({}, { __index = Condition })
GainDebuffCondition.__index = GainDebuffCondition
GainDebuffCondition.__type = "GainDebuffCondition"
GainDebuffCondition.__class = "GainDebuffCondition"

function GainDebuffCondition.new(debuff_name, target_index)
    local self = setmetatable(Condition.new(target_index), GainDebuffCondition)
    self.debuff_name = debuff_name or "poison"
    self.debuff_id = buff_util.buff_id(self.debuff_name)
    return self
end

function GainDebuffCondition:is_satisfied(target_index, debuff_name)
    return self.debuff_name == debuff_name
end

function GainDebuffCondition:get_config_items()
    local all_debuffs = S(buff_util.get_all_debuff_ids():map(function(debuff_id)
        local debuff = res.buffs[debuff_id]
        if debuff then
            return debuff.en
        end
        return nil
    end):compact_map())
    all_debuffs = L(all_debuffs)
    all_debuffs:sort()

    return L{
        PickerConfigItem.new('debuff_name', self.debuff_name, all_debuffs, function(debuff_name)
            return debuff_name:gsub("^%l", string.upper)
        end, "Status Ailment")
    }
end

function GainDebuffCondition:tostring()
    return "Is now "..res.buffs:with('en', self.debuff_name).enl
end

function GainDebuffCondition.description()
    return "Gain debuff."
end

function GainDebuffCondition:serialize()
    return "GainDebuffCondition.new(" .. serializer_util.serialize_args(self.debuff_name) .. ")"
end

return GainDebuffCondition




