---------------------------
-- Condition checking whether the player or party member has a pet.
-- @class module
-- @name HasPetCondition

local GroupConfigItem = require('ui/settings/editors/config/GroupConfigItem')
local localization_util = require('cylibs/util/localization_util')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local HasPetCondition = setmetatable({}, { __index = Condition })
HasPetCondition.__index = HasPetCondition
HasPetCondition.__type = "HasPetCondition"
HasPetCondition.__class = "HasPetCondition"

function HasPetCondition.new(pet_names, target_index)
    local self = setmetatable(Condition.new(target_index), HasPetCondition)
    self.pet_names = pet_names or L{}
    return self
end

function HasPetCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(self:get_target_index() or target_index)
    if target then
        if target.id == windower.ffxi.get_player().id then
            local pet = pet_util.get_pet()
            return pet and (self.pet_names:contains(pet.name) or self.pet_names:empty())
        else
            local pet_index = target.pet_index
            if pet_index and pet_index ~= 0 then
                local pet = windower.ffxi.get_mob_by_index(pet_index)
                return pet and (self.pet_names:contains(pet.name) or self.pet_names:empty())
            end
        end
    end
    return false
end

function HasPetCondition:get_config_items()
    local all_pet_names = L{}:extend(self.pet_names):extend(L{
        'None',
        'VivaciousVickie',
        'CaringKiyomaro',
    }):compact_map():sort()
    return L{
        GroupConfigItem.new('pet_names', L{
            PickerConfigItem.new('pet_name_1', self.pet_names:length() > 0 and self.pet_names[1] or 'None', all_pet_names, nil, "Pet Name"),
        }, nil, "PetName")
    }
end

function HasPetCondition:tostring()
    if self.pet_names:length() > 0 then
        return "Has pet named "..localization_util.commas(self.pet_names, 'or')
    else
        return "Has pet"
    end
end

function HasPetCondition.description()
    return "Has pet."
end

function HasPetCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function HasPetCondition:serialize()
    return "HasPetCondition.new(" .. serializer_util.serialize_args(self.pet_names) .. ")"
end

return HasPetCondition




