---
-- @module ValueRelay
--

local Event = require('cylibs/events/Luvent')

local ValueRelay = {}
ValueRelay.__index = ValueRelay

function ValueRelay:onValueChanged()
    return self.valueChanged
end

---
-- Creates a new ValueRelay instance.
--
-- @tparam any value The initial value to relay.
-- @treturn ValueRelay The newly created ValueRelay instance.
--
function ValueRelay.new(value)
    local self = setmetatable({}, ValueRelay)
    self.value = value
    self.valueChanged = Event.newEvent()
    return self
end

---
-- Destroys the value relay.
--
--
function ValueRelay:destroy()
    self.valueChanged:removeAllActions()
end

---
-- Retrieves the current relayed value.
--
-- @treturn any The current relayed value.
--
function ValueRelay:getValue()
    return self.value
end

---
-- Sets a new value to be relayed and triggers the valueChanged event.
--
-- @tparam any newValue The new value to be relayed.
--
function ValueRelay:setValue(newValue)
    self.value = newValue

    self:onValueChanged():trigger(self, newValue)
end

return ValueRelay
