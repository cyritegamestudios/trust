local LayoutConstraint = require('cylibs/ui/layout/constraints/layout_constraint')

local HorizontalAlignmentConstraint = setmetatable({}, { __index = LayoutConstraint })
HorizontalAlignmentConstraint.__index = HorizontalAlignmentConstraint
HorizontalAlignmentConstraint.__class = "HorizontalAlignmentConstraint"

function HorizontalAlignmentConstraint.new(alignment)
    local self = setmetatable(LayoutConstraint.new(), HorizontalAlignmentConstraint)
    self.alignment = alignment
    return self
end

function HorizontalAlignmentConstraint:apply(view)
end

function HorizontalAlignmentConstraint:__eq(otherItem)
    return otherItem.__class == LayoutConstraint.__class
            and otherItem.alignment == self.alignment
end

return HorizontalAlignmentConstraint