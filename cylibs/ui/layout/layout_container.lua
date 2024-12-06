local LayoutContainer = {}
LayoutContainer.__index = LayoutContainer
LayoutContainer.__type = "LayoutContainer"

---
-- Creates a new alignment instance.
--
-- @tparam string type Alignment type
-- @treturn Alignment The newly created Alignment instance.
--
function LayoutContainer.new()
    local self = setmetatable({}, LayoutContainer)
    self.constraints = S{}
    return self
end

function LayoutContainer:destroy()
end

function LayoutContainer:addConstraint(constraint)
    if self.constraints:contains(constraint) then
        return
    end
    self.constraints:add(constraint)
end

function LayoutContainer:removeConstraint(constraint)
    if self.constraints:contains(constraint) then
        constraint:destroy()
        self.constraints:remove(constraint)
    end
end

function LayoutContainer:removeAllConstraints()
    for constraint in self.constraints:it() do
        constraint:destroy()
    end
    self.constraints = S{}
end

function LayoutContainer:applyConstraints(view)
    for constraint in self.constraints:it() do

    end
end

function LayoutContainer:__eq(otherItem)
    return otherItem.__type == LayoutContainer.__type
            and self.type == otherItem:getType()
end

return LayoutContainer