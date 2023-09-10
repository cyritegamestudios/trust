local Layout = require('cylibs/ui/layouts/layout')

local HorizontalListLayout = setmetatable({}, {__index = Layout })
HorizontalListLayout.__index = HorizontalListLayout

function HorizontalListLayout.new(layoutHeight, itemOffset)
    local self = setmetatable(Layout.new(itemOffset), HorizontalListLayout)

    self.itemOffset = itemOffset

    self:setSize(0, layoutHeight)

    return self
end

---
-- Destroys the layout, cleaning up its resources.
--
function HorizontalListLayout:destroy()
    Layout.destroy(self)
end

function HorizontalListLayout:layout(itemViews, items)
    local _, layoutHeight = self:getSize()
    local xOffset, yOffset = self:getOffset()
    local layoutWidth = xOffset

    for item in items:it() do
        local itemView = itemViews[item]
        if itemView then
            local width, _ = itemView:get_size()
            itemView:set_size(width, layoutHeight)
            itemView:set_pos(layoutWidth, yOffset)
            itemView:render()
            layoutWidth = layoutWidth + width + self.itemOffset
        end
    end
    self:setSize(layoutWidth - xOffset, layoutHeight)
end

return HorizontalListLayout