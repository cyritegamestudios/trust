local LayoutConstraint = {}
LayoutConstraint.__index = LayoutConstraint
LayoutConstraint.__class = "LayoutConstraint"

function LayoutConstraint.new()
    local self = setmetatable({}, LayoutConstraint)
    return self
end

function LayoutConstraint:destroy()
end

function LayoutConstraint:apply(view)
end

function LayoutConstraint:__eq(otherItem)
    return otherItem.__class == LayoutConstraint.__class
end

return LayoutConstraint