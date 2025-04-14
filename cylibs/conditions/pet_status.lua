---------------------------
-- Condition checking a pet's status, optionally for a specified duration.
-- @class module
-- @name PetStatusCondition

local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PetStatusCondition = setmetatable({}, { __index = Condition })
PetStatusCondition.__index = PetStatusCondition
PetStatusCondition.__type = "PetStatusCondition"
PetStatusCondition.__class = "PetStatusCondition"

function PetStatusCondition.new(status_name)
    local self = setmetatable(Condition.new(), PetStatusCondition)
    self.status_name = status_name or 'Idle'
    return self
end

function PetStatusCondition:is_satisfied(_)
    local pet = windower.ffxi.get_mob_by_target('pet')
    if pet ~= nil then
        return res.statuses[pet.status].en == self.status_name
    end
    return false
end

function PetStatusCondition:get_config_items()
    local allStatuses = L{ 0, 1, 2, 3, 4, 5, 33, 44, 85 }:map(function(status_id)
        return res.statuses[status_id].en
    end):compact_map()
    return L{
        PickerConfigItem.new('status_name', self.status_name, allStatuses, nil, "Status"),
    }
end

function PetStatusCondition:tostring()
    return "Pet is "..self.status_name
end

function PetStatusCondition.description()
    return "Pet status is X."
end

function PetStatusCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function PetStatusCondition:serialize()
    return "PetStatusCondition.new(" .. serializer_util.serialize_args(self.status_name) .. ")"
end

return PetStatusCondition




