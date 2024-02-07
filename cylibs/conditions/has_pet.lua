---------------------------
-- Condition checking whether the player or party member has a pet.
-- @class module
-- @name HasPetCondition

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
        local pet_index = target.pet_index
        if pet_index and pet_index ~= 0 then
            local pet = windower.ffxi.get_mob_by_index(pet_index)
            return pet and (self.pet_names:contains(pet.name) or self.pet_names:empty())
        end
    end
    return false
end

function HasPetCondition:tostring()
    return "HasPetCondition"
end

function HasPetCondition:serialize()
    return "HasPetCondition.new(" .. serializer_util.serialize_args(self.pet_names) .. ")"
end

return HasPetCondition




