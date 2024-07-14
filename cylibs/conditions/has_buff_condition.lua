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
    self.buff_name = buff_name or "Refresh"
    self.buff_id = buff_util.buff_id(self.buff_name)
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
    local all_buffs = buff_util.get_all_buff_ids(true):map(function(buff_id)
        return res.buffs[buff_id].en
    end)
    all_buffs:sort()
    print(all_buffs)

    return L{
        PickerConfigItem.new('buff_name', self.buff_name, all_buffs, function(buff_name)
            return buff_name:gsub("^%l", string.upper)
        end, "Buff Name")
    }
end

function HasBuffCondition:tostring()
    return "Player is "..res.buffs:with('en', self.buff_name).enl
end

function HasBuffCondition:serialize()
    return "HasBuffCondition.new(" .. serializer_util.serialize_args(self.buff_name) .. ")"
end

return HasBuffCondition




