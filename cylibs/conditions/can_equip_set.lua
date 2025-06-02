---------------------------
-- Condition checking whether the target has any of the given combat skills.
-- @class module
-- @name CanEquipSetCondition
local EquipSet = require('cylibs/inventory/equipment/equip_set')
local Item = require('resources/resources').Item
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local CanEquipSetCondition = setmetatable({}, { __index = Condition })
CanEquipSetCondition.__index = CanEquipSetCondition
CanEquipSetCondition.__type = "CanEquipSetCondition"
CanEquipSetCondition.__class = "CanEquipSetCondition"

function CanEquipSetCondition.new(equip_set_name)
    local self = setmetatable(Condition.new(), CanEquipSetCondition)
    self.equip_set_name = equip_set_name
    return self
end

function CanEquipSetCondition:is_satisfied(_)
    local target = player.party:get_player()
    if target then
        local equip_set = self.equip_set_name and EquipSet.named(self.equip_set_name)
        if equip_set then
            if equip_set.main and equip_set.sub then
                local main = Item:where({ id = equip_set.main }, L{ 'skill' })[1]
                local sub = Item:where({ id = equip_set.sub }, L{ 'skill', 'shield_size' })[1]

                -- 1. 2H weapon + shield
                if L{ 4, 6, 7, 8, 10, 12 }:contains(main.skill) and sub.skill == 30 or sub.shield_size then
                    return false
                end

                -- 2. 1H weapon + grip
                if L{ 2, 3, 5, 9, 11 }:contains(main.skill) and sub.skill == 0 then
                    return false
                end

                -- 3. H2H and sub
                if main.skill == 1 and sub then
                    return false
                end
            end
            if equip_set.range and equip_set.ammo then
                -- 4. range and ammo
                -- if range has a skill and ammo has a skill they have to match (animator might be an exception)
                local range = Item:where({ id = equip_set.range }, L{ 'skill' })[1]
                local ammo = Item:where({ id = equip_set.ammo }, L{ 'skill' })[1]

                if range.skill == 0 and ammo.skill == 0 then
                    return false
                end

                if range.skill and ammo.skill and range.skill ~= ammo.skill then
                    return false
                end
            end

            for slot_id, item_id in equip_set:it() do
                -- check level
                -- check jobs
                -- check race
            end
            return true
        end
    end
    return false
end

function CanEquipSetCondition:get_config_items()
    return L{}
end

function CanEquipSetCondition:tostring()
    return string.format("Can equip %s", self.equip_set_name)
end

function CanEquipSetCondition.description()
    return "Can equip set."
end

function CanEquipSetCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function CanEquipSetCondition:serialize()
    return "CanEquipSetCondition.new(" .. serializer_util.serialize_args(self.equip_set_name) .. ")"
end

function CanEquipSetCondition:__eq(otherItem)
    return otherItem.__class == CanEquipSetCondition.__class
            and otherItem.equip_set_name == self.equip_set_name
end

return CanEquipSetCondition




