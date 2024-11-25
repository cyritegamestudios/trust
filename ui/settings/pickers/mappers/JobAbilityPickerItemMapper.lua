local JobAbility = require('cylibs/battle/abilities/job_ability')

local PickerItemMapper = require('ui/settings/pickers/mappers/PickerItemMapper')
local JobAbilityPickerItemMapper = setmetatable({}, {__index = PickerItemMapper })
JobAbilityPickerItemMapper.__index = JobAbilityPickerItemMapper

function JobAbilityPickerItemMapper.new()
    local self = setmetatable(PickerItemMapper.new(), JobAbilityPickerItemMapper)
    return self
end

---
-- Returns whether this PickerItemMapper can map a given picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn boolean True if this mapper can map a picker item.
--
function JobAbilityPickerItemMapper:canMap(value)
    return S{ JobAbility.__type }:contains(value.__type)
end

---
-- Gets the mapped picker item.
--
-- @tparam PickerItem pickerItem The PickerItem.
-- @treturn table The mapped picker item.
--
function JobAbilityPickerItemMapper:map(value)
    return JobAbility.new(value:get_name(), L{}, L{})
end

return JobAbilityPickerItemMapper