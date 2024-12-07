local StatusAilment = {}
StatusAilment.__index = StatusAilment
StatusAilment.__type = "StatusAilment"
StatusAilment.__class = "StatusAilment"

-------
-- Default initializer for a new status ailment.
-- @tparam string debuff_name Name of the debuff
-- @treturn StatusAilment A status ailment
function StatusAilment.new(debuff_name)
    local self = setmetatable({}, StatusAilment)

    self.debuff_name = debuff_name

    return self
end

function StatusAilment:get_name()
    return self.debuff_name
end

function StatusAilment:get_localized_name()
    return i18n.resource('buffs', 'en', self:get_name())
end

function StatusAilment:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_name() == self:get_name() then
        return true
    end
    return false
end

return StatusAilment